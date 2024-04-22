# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Common Starlark helpers used by apple_support tests."""

visibility(["//test/..."])

# Common tags used for all test fixtures to ensure that they don't build unless
# used as a dependency of a test.
FIXTURE_TAGS = [
    "manual",
]

def make_unique_namer(*, prefix, index):
    """Returns a function used to generate unique names in a package.

    When generating multiple test fixtures in a single `.bzl` file that contains
    multiple test macros, you generally don't want to worry about ensuring that
    all the fixture targets have unique names. This utility makes that easier by
    returning a simple function that can be used to generate unique names based
    on a prefix and index of the test being created. See `make_all_tests` for
    how this is used in practice (most users will not need to call this
    directly.)

    Notice that the returned function handles same-package label references
    (beginning with `:`) correctly as well.
    """

    def namer(suffix):
        if suffix.startswith(":"):
            return ":{}__{}__{}".format(prefix, index, suffix[1:])
        return "{}__{}__{}".format(prefix, index, suffix)

    return namer

def make_all_tests(*, name, tests, tags = []):
    """Makes all of the tests defined by a list of test functions.

    This function simplifies the process of creating Starlark tests and the
    corresponding test suite. It should be called from a test-creation macro
    with the desired name of the test suite target, which will be used to create
    a unique namer for fixtures created by the macro, and a list of other test
    macros that each represents a test and its fixtures.

    Each entry in `tests` passed to this function should have the following
    behavior:

    *   It must take a single `namer` argument that will be a function returned
        by `make_unique_namer` that the test should use to create unique names
        for its fixture targets.
    *   It must return a list of names of the test targets (not fixtures, just
        actual tests) that it created so that they can be added to the test
        suite.

    ```build
    def some_test_macro(name):
        make_all_tests(
            name = name,
            tests = [
                test1,
                test2,
            ],
        )

    def test1(namer):
        some_target(
            name = namer("foo"),
            some_label = namer(":bar")
        )
        some_test(
            name = "test1",
            target_under_test = namer(":foo"),
        )
        return ["test1"]
    ```
    """
    native.test_suite(
        name = name,
        tests = [
            returned_test
            for index, test_creator in enumerate(tests)
            for returned_test in test_creator(
                namer = make_unique_namer(prefix = name, index = index + 1),
            )
        ],
        tags = tags,
    )
