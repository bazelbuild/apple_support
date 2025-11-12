// Copyright 2025 The Bazel Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <spawn.h>
#include <unistd.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <regex>
#include <sstream>
#include <unordered_set>

extern char **environ;

const std::regex libRegex = std::regex(".*\\.a$");
const std::regex singleArgFlags = std::regex("-arch_only|-syslibroot|-o");

// An RAII temporary directory.
class TempDirectory {
 public:
  // Create a new temporary directory. The directory will automatically be
  // deleted when the object goes out of scope.
  static std::unique_ptr<TempDirectory> Create() {
    std::filesystem::path temp_path = std::filesystem::temp_directory_path() /
                                      "bazel_libtool_symlinks.XXXXXXX";
    std::unique_ptr<char[]> path(new char[temp_path.string().size() + 1]);
    std::strcpy(path.get(), temp_path.string().c_str());

    char *temp_dir = mkdtemp(path.get());
    if (temp_dir == nullptr) {
      std::cerr << "error: failed to create temporary directory" << std::endl;
      exit(EXIT_FAILURE);
    }

    return std::unique_ptr<TempDirectory>(new TempDirectory(path.get()));
  }

  // Explicitly make TempDirectory non-copyable and movable.
  TempDirectory(const TempDirectory &) = delete;
  TempDirectory &operator=(const TempDirectory &) = delete;
  TempDirectory(TempDirectory &&) = default;
  TempDirectory &operator=(TempDirectory &&) = default;

  ~TempDirectory() { std::filesystem::remove_all(path_.c_str()); }

  std::filesystem::path GetPath() const { return path_; }

 private:
  explicit TempDirectory(const std::string &path) : path_(path) {}

  std::string path_;
};

// Returns the DEVELOPER_DIR environment variable in the current process
// environment. Aborts if this variable is unset.
std::string getMandatoryEnvVar(const std::string &var_name) {
  char *env_value = getenv(var_name.c_str());
  if (env_value == nullptr) {
    std::cerr << "error: " << var_name << " not set.\n";
    exit(EXIT_FAILURE);
  }
  return env_value;
}

// Returns the base name of the given filepath. For example, given
// /foo/bar/baz.txt, returns 'baz.txt'.
const char *basename(const char *filepath) {
  const char *base = strrchr(filepath, '/');
  return base ? (base + 1) : filepath;
}

// Converts an array of string arguments to char *arguments.
// The first arg is reduced to its basename as per execve conventions.
// Note that the lifetime of the char* arguments in the returned array
// are controlled by the lifetime of the strings in args.
std::vector<const char *> ConvertToCArgs(const std::vector<std::string> &args) {
  std::vector<const char *> c_args;
  c_args.push_back(basename(args[0].c_str()));
  for (int i = 1; i < args.size(); i++) {
    c_args.push_back(args[i].c_str());
  }
  c_args.push_back(nullptr);
  return c_args;
}

// Spawns a subprocess for given arguments args. The first argument is used
// for the executable path.
bool runSubProcess(const std::vector<std::string> &args) {
  int pipefd[2];  // File descriptors for the pipe
  if (pipe(pipefd) == -1) {
    perror("pipe failed");
    return false;
  }

  std::vector<const char *> exec_argv = ConvertToCArgs(args);
  pid_t pid;
  posix_spawn_file_actions_t actions;
  posix_spawn_file_actions_init(&actions);

  // Redirect child's stderr to the write end of the pipe
  posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDERR_FILENO);
  posix_spawn_file_actions_addclose(&actions,
                                    pipefd[0]);  // Close unused read end

  int status = posix_spawn(&pid, args[0].c_str(), &actions, nullptr,
                           const_cast<char **>(exec_argv.data()), environ);
  close(pipefd[1]);  // Close write end in the parent
  if (status == 0) {
    posix_spawn_file_actions_destroy(&actions);
    int wait_status;
    char buffer[256];

    // Drain stderr pipe first, once closed we'll check waitpid
    ssize_t count;
    std::ostringstream oss;
    while ((count = read(pipefd[0], buffer, sizeof(buffer) - 1)) > 0) {
      oss.write(buffer, count);
    }

    do {
      wait_status = waitpid(pid, &status, 0);
    } while ((wait_status == -1) && (errno == EINTR));

    std::stringstream ss(oss.str());
    std::string line;
    while (std::getline(ss, line)) {
      if (line.find("(no object file members in the library define global "
                    "symbols)") == std::string::npos) {
        std::cerr << line << "\n";
      }
    }

    close(pipefd[0]);  // Close read end

    if (wait_status < 0) {
      std::cerr << "Error waiting on child process '" << args[0] << "'. "
                << strerror(errno) << "\n";
      return false;
    }
    if (WIFEXITED(status) && WEXITSTATUS(status) != 0) {
      std::cerr << "Child process '" << args[0]
                << "' terminated with exit code "
                << WEXITSTATUS(status)
                << "\nstderr:\n"
                << oss.str();
      return false;
    } else if (WIFSIGNALED(status)) {
      std::cerr << "Child process '" << args[0]
                << "' terminated with signal "
                << WTERMSIG(status)
                << "\nstderr:\n"
                << oss.str();
      return false;
    }
  } else {
    std::cerr << "Error forking process '" << args[0] << "'. "
              << strerror(status) << "\n";
    return false;
  }

  return true;
}

// Finds and replaces all instances of oldsub with newsub, in-place on str.
void findAndReplace(const std::string &oldsub, const std::string &newsub,
                    std::string *str) {
  int start = 0;
  while ((start = str->find(oldsub, start)) != std::string::npos) {
    str->replace(start, oldsub.length(), newsub);
    start += newsub.length();
  }
}

std::string rewriteArg(const std::string arg, const std::string developer_dir,
                       const std::string sdk_root) {
  auto new_arg = arg;
  findAndReplace("__BAZEL_XCODE_DEVELOPER_DIR__", developer_dir, &new_arg);
  findAndReplace("__BAZEL_XCODE_SDKROOT__", sdk_root, &new_arg);
  return new_arg;
}

bool hasDuplicateBasenames(const std::vector<std::string> files) {
  std::unordered_set<std::string> basenames;
  for (std::filesystem::path path : files) {
    const auto pair = basenames.insert(path.filename());
    if (!pair.second) {
      return true;
    }
  }

  return false;
}

void processArgs(const std::vector<std::string> args,
                 std::function<void(const std::string &)> flags_consumer,
                 std::function<void(const std::string &)> files_consumer) {
  for (auto it = args.begin(); it != args.end(); ++it) {
    const std::string arg = *it;
    if (arg == "-filelist") {
      ++it;
      std::ifstream list(*it);
      for (std::string line; std::getline(list, line);) {
        files_consumer(line);
      }
    } else if (arg[0] == '@') {
      std::string paramsFilePath(arg.substr(1));
      std::ifstream params_file(paramsFilePath);

      std::vector<std::string> params_file_args = {};
      for (std::string line; std::getline(params_file, line);) {
        params_file_args.push_back(line);
      }
      processArgs(params_file_args, flags_consumer, files_consumer);
    } else if (regex_match(arg, singleArgFlags)) {
      flags_consumer(arg);
      ++it;
      flags_consumer(*it);
    } else if (regex_match(arg, libRegex)) {
      flags_consumer(arg);
    } else if (arg[0] == '-') {  // Assume any dashed flag is valid, otherwise
                                 // it will fail in real libtool anyways
      flags_consumer(arg);
    } else {  // Assume all other args are object files
      files_consumer(arg);
    }
  }
}

std::string hash(const std::string &input) {
  std::hash<std::string> hasher;
  size_t hashValue = hasher(input);

  std::ostringstream oss;
  oss << std::hex << std::setw(sizeof(size_t) * 2) << std::setfill('0')
      << hashValue;

  return oss.str();
}

void createSymlinks(std::filesystem::path temp_directory,
                    const std::vector<std::string> files,
                    std::function<void(const std::string &)> files_consumer) {
  for (auto file : files) {
    std::filesystem::path path = file;

    std::hash<std::string> hasher;
    hasher(file);

    std::string new_basename = path.stem();
    new_basename.append("_");
    new_basename.append(hash(file));
    new_basename.append(".o");
    auto link = temp_directory / new_basename;

    std::filesystem::create_symlink(std::filesystem::absolute(path), link);

    files_consumer(link);
  }
}

int main(int argc, const char *argv[]) {
  std::vector<std::string> args;
  // Set i to 1 to skip executable path
  for (int i = 1; argv[i] != nullptr; i++) {
    args.push_back(argv[i]);
  }

  std::string developer_dir = getMandatoryEnvVar("DEVELOPER_DIR");
  std::string sdk_root = getMandatoryEnvVar("SDKROOT");

  // NOTE: Order of libtool flags interspersed with files does not matter, but
  // maintaining file order might?
  std::vector<std::string> processed_args = {};
  std::vector<std::string> files = {};
  auto flags_consumer = [&](const std::string &arg) {
    processed_args.push_back(rewriteArg(arg, developer_dir, sdk_root));
  };
  auto files_consumer = [&](const std::string &arg) {
    files.push_back(rewriteArg(arg, developer_dir, sdk_root));
  };

  processArgs(args, flags_consumer, files_consumer);

  std::unique_ptr<TempDirectory> temp_directory = TempDirectory::Create();
  if (hasDuplicateBasenames(files)) {
    createSymlinks(temp_directory->GetPath(), files, flags_consumer);
  } else {
    processed_args.insert(processed_args.end(), files.begin(), files.end());
  }

  auto response_file = temp_directory->GetPath() / "bazel_libtool.params";
  std::ofstream response_file_stream(response_file);
  for (const auto &arg : processed_args) {
    response_file_stream << '"';
    for (auto ch : arg) {
      if (ch == '"') {
        response_file_stream << '\\';
      }
      response_file_stream << ch;
    }
    response_file_stream << "\"\n";
  }
  response_file_stream.close();

  std::vector<std::string> invocation_args = {
      "/usr/bin/xcrun",
      "libtool",
      "@" + response_file.u8string(),
  };

  if (!runSubProcess(invocation_args)) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
