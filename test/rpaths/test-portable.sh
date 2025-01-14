#!/bin/bash

set -euo pipefail

# Without valid rpaths the binary will only work from a specific PWD

./test/rpaths/test
cd ./test
./rpaths/test
cd ./rpaths
./test
