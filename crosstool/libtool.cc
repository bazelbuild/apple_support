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
#include <sys/wait.h>
#include <unistd.h>

#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <memory>
#include <regex>
#include <sstream>
#include <string>
#include <unordered_set>
#include <vector>

extern char** environ;

const std::regex libRegex = std::regex(".*\\.a$");
const std::regex singleArgFlags = std::regex("-arch_only|-o");
const std::unordered_set<char> supportedArFlags = {
    'c', 'r', 'q', 's', 'D',
};

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

    char* temp_dir = mkdtemp(path.get());
    if (temp_dir == nullptr) {
      std::cerr << "error: failed to create temporary directory" << std::endl;
      exit(EXIT_FAILURE);
    }

    return std::unique_ptr<TempDirectory>(new TempDirectory(path.get()));
  }

  // Explicitly make TempDirectory non-copyable and movable.
  TempDirectory(const TempDirectory&) = delete;
  TempDirectory& operator=(const TempDirectory&) = delete;
  TempDirectory(TempDirectory&&) = default;
  TempDirectory& operator=(TempDirectory&&) = default;

  ~TempDirectory() { std::filesystem::remove_all(path_.c_str()); }

  std::filesystem::path GetPath() const { return path_; }

 private:
  explicit TempDirectory(const std::string& path) : path_(path) {}

  std::string path_;
};

// Returns the DEVELOPER_DIR environment variable in the current process
// environment. Aborts if this variable is unset.
std::string getMandatoryEnvVar(const std::string& var_name) {
  char* env_value = getenv(var_name.c_str());
  if (env_value == nullptr) {
    std::cerr << "error: " << var_name << " not set.\n";
    exit(EXIT_FAILURE);
  }
  return env_value;
}

// Returns the base name of the given filepath. For example, given
// /foo/bar/baz.txt, returns 'baz.txt'.
const char* basename(const char* filepath) {
  const char* base = strrchr(filepath, '/');
  return base ? (base + 1) : filepath;
}

// Converts an array of string arguments to char *arguments.
// The first arg is reduced to its basename as per execve conventions.
// Note that the lifetime of the char* arguments in the returned array
// are controlled by the lifetime of the strings in args.
std::vector<const char*> ConvertToCArgs(const std::vector<std::string>& args) {
  std::vector<const char*> c_args;
  c_args.push_back(basename(args[0].c_str()));
  for (int i = 1; i < args.size(); i++) {
    c_args.push_back(args[i].c_str());
  }
  c_args.push_back(nullptr);
  return c_args;
}

// Spawns a subprocess for given arguments args. The first argument is used
// for the executable path.
bool runSubProcess(const std::vector<std::string>& args) {
  int pipefd[2];  // File descriptors for the pipe
  if (pipe(pipefd) == -1) {
    perror("pipe failed");
    return false;
  }

  std::vector<const char*> exec_argv = ConvertToCArgs(args);
  pid_t pid;
  posix_spawn_file_actions_t actions;
  posix_spawn_file_actions_init(&actions);

  // Redirect child's stderr to the write end of the pipe
  posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDERR_FILENO);
  posix_spawn_file_actions_addclose(&actions,
                                    pipefd[0]);  // Close unused read end

  int status = posix_spawn(&pid, args[0].c_str(), &actions, nullptr,
                           const_cast<char**>(exec_argv.data()), environ);
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
                << "' terminated with exit code " << WEXITSTATUS(status)
                << "\nstderr:\n"
                << oss.str();
      return false;
    } else if (WIFSIGNALED(status)) {
      std::cerr << "Child process '" << args[0] << "' terminated with signal "
                << WTERMSIG(status) << "\nstderr:\n"
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
void findAndReplace(const std::string& oldsub, const std::string& newsub,
                    std::string* str) {
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

bool hasOnlyArFlags(const std::string& arg) {
  if (arg.empty()) {
    return false;
  }
  for (char flag : arg) {
    if (supportedArFlags.find(flag) == supportedArFlags.end()) {
      return false;
    }
  }
  return true;
}

bool isArTocOnlyInvocation(const std::vector<std::string>& args) {
  return args.size() == 2 && args[0].find('s') != std::string::npos &&
         args[0].find('c') == std::string::npos &&
         args[0].find('r') == std::string::npos &&
         args[0].find('q') == std::string::npos;
}

[[noreturn]] void processArTocOnlyArgsAndExit(
    const std::vector<std::string>& args) {
  const std::string archive = args[1];
  if (!regex_match(archive, libRegex)) {
    std::cerr << "error: expected archive file after ar flags '" << args[0]
              << "', got '" << archive
              << "'. Please report this to apple_support.\n";
    exit(EXIT_FAILURE);
  }
  if (!std::filesystem::exists(archive)) {
    std::cerr << "error: attempted to create TOC but archive file '" << archive
              << "' does not exist. Please report this to apple_support.\n";
    exit(EXIT_FAILURE);
  }
  exit(EXIT_SUCCESS);
}

bool looksLikeArInvocation(const std::vector<std::string>& args) {
  if (args.empty()) {
    return false;
  }
  if (hasOnlyArFlags(args[0])) {
    return true;
  }
  // If the first arg starts with a -, it's unlikely ar which is usually 'ar cr
  // libfoo.a foo.o'
  if (args[0].empty() || args[0][0] == '-') {
    return false;
  }
  return args.size() >= 2 && regex_match(args[1], libRegex);
}

void processArCreateArgs(
    const std::vector<std::string>& args,
    std::function<void(const std::string&)> flags_consumer) {
  if (!hasOnlyArFlags(args[0])) {
    std::cerr << "error: unsupported ar flags '" << args[0]
              << "'. Supported flag characters are 'c', 'r', 'q', 's', "
              << "and 'D'. Please file an issue at "
              << "https://github.com/bazelbuild/apple_support/issues if this "
              << "needs to support another ar invocation.\n";
    exit(EXIT_FAILURE);
  }
  if (args.size() < 2) {
    std::cerr << "error: expected output archive after ar flags '" << args[0]
              << "'.\n";
    exit(EXIT_FAILURE);
  }
  if (!regex_match(args[1], libRegex)) {
    std::cerr << "error: expected output archive after ar flags '" << args[0]
              << "', got '" << args[1] << "'.\n";
    exit(EXIT_FAILURE);
  }
  if (args.size() < 3) {
    std::cerr
        << "error: expected at least one input file after output archive '"
        << args[1] << "'.\n";
    exit(EXIT_FAILURE);
  }

  flags_consumer("-static");
  flags_consumer("-D");  // NOTE: Always added for hermiticity
  flags_consumer("-o");
  flags_consumer(args[1]);
}

void processArgs(const std::vector<std::string> args,
                 std::function<void(const std::string&)> flags_consumer,
                 std::function<void(const std::string&)> files_consumer) {
  auto start = args.begin();
  if (looksLikeArInvocation(args)) {
    if (isArTocOnlyInvocation(args)) {
      processArTocOnlyArgsAndExit(args);
    }

    processArCreateArgs(args, flags_consumer);
    start += 2;
  }

  for (auto it = start; it != args.end(); ++it) {
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

void logInvocation(const std::vector<std::string>& invocation_args,
                   const std::vector<std::string>& processed_args) {
  bool first = true;
  auto log_arg = [&](const std::string& arg) {
    if (!first) {
      std::cout << ' ';
    }
    std::cout << arg;
    first = false;
  };

  for (const std::string& arg : invocation_args) {
    log_arg(arg);
  }
  for (const std::string& arg : processed_args) {
    log_arg(arg);
  }
  std::cout << "\n";
}

std::string hash(const std::string& input) {
  std::hash<std::string> hasher;
  size_t hashValue = hasher(input);

  std::ostringstream oss;
  oss << std::hex << std::setw(sizeof(size_t) * 2) << std::setfill('0')
      << hashValue;

  return oss.str();
}

void createSymlinks(std::filesystem::path temp_directory,
                    const std::vector<std::string> files,
                    std::function<void(const std::string&)> files_consumer) {
  for (auto file : files) {
    std::filesystem::path path = file;

    std::string new_basename = path.stem();
    new_basename.append("_");
    new_basename.append(hash(file));
    new_basename.append(".o");
    auto link = temp_directory / new_basename;

    std::filesystem::create_symlink(std::filesystem::absolute(path), link);

    files_consumer(link);
  }
}

int main(int argc, const char* argv[]) {
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
  auto flags_consumer = [&](const std::string& arg) {
    processed_args.push_back(rewriteArg(arg, developer_dir, sdk_root));
  };
  auto files_consumer = [&](const std::string& arg) {
    files.push_back(rewriteArg(arg, developer_dir, sdk_root));
  };

  processArgs(args, flags_consumer, files_consumer);

  std::unique_ptr<TempDirectory> temp_directory = TempDirectory::Create();
  if (hasDuplicateBasenames(files)) {
    createSymlinks(temp_directory->GetPath(), files, flags_consumer);
  } else {
    processed_args.insert(processed_args.end(), files.begin(), files.end());
  }

  std::vector<std::string> invocation_args = {
      "/usr/bin/xcrun",
      "libtool",
  };

  // Used for testing.
  if (getenv("__LIBTOOL_LOG_ONLY")) {
    logInvocation(invocation_args, processed_args);
    return EXIT_SUCCESS;
  }

  auto response_file = temp_directory->GetPath() / "bazel_libtool.params";
  std::ofstream response_file_stream(response_file);
  for (const auto& arg : processed_args) {
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

  invocation_args.push_back("@" + response_file.u8string());

  if (!runSubProcess(invocation_args)) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
