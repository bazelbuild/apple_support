#include <stdio.h>
#include <string.h>

#include "linkstamp.h"

int main() {
  const char* host = build_host;
  fprintf(stdout, "BUILD_HOST: '%s'\n", host);
  if (host == nullptr || host[0] == '\0') {
    fprintf(stderr, "BUILD_HOST not set or empty\n");
    return 1;
  }
  if (strcmp(host, "redacted") == 0) {
    fprintf(stderr, "BUILD_HOST is \"redacted\", linkstamp not working\n");
    return 1;
  }

  return 0;
}
