#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

#include "loadable_library.h"

int main() {
  if (loadable_library() != 42) {
    fprintf(stderr, "loadable_library() returned wrong value\n");
    return 1;
  }

  Dl_info info;
  if (dladdr((void *)&loadable_library, &info) == 0) {
    fprintf(stderr, "dladdr failed to find loadable_library symbol\n");
    return 1;
  }

  const char *dylib = strstr(info.dli_fname, ".dylib");
  const char *so = strstr(info.dli_fname, ".so");
  if (!dylib && !so) {
    fprintf(stderr,
            "loadable_library is not in a shared library, found in: %s\n",
            info.dli_fname);
    return 1;
  }

  return 0;
}
