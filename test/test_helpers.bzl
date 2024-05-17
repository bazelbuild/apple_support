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

load("@bazel_skylib//lib:unittest.bzl", "analysistest")

visibility(["//test/..."])

# Common tags used for all test fixtures to ensure that they don't build unless
# used as a dependency of a test.
FIXTURE_TAGS = [
    "manual",
]

def assert_warning(env, msg_id, data = None):
    """Asserts that a warning was printed.

    The logic in this helper is specifically meant to handle warnings printed by
    `xcode_config.bzl`, because we want to preserve the behavior of the original
    rules and their tests.

    Args:
        env: The analysis test environment.
        msg_id: The fixed identifier of the warning message.
        data: The semicolon-delimited, sorted by key, `key=value` string
            representation of the format arguments for the message, if any.
    """
    expected = "Warning:{}".format(msg_id)
    if data:
        expected += ":{}".format(data)

    found_warnings = []

    actions = analysistest.target_actions(env)
    for action in actions:
        mnemonic = action.mnemonic
        if mnemonic == expected:
            return
        if mnemonic.startswith("Warning:"):
            found_warnings.append(mnemonic)

    found_warnings_msg = ""
    if found_warnings:
        found_warnings_msg = "; the following warnings were emitted:\n{}".format(
            "\n".join(found_warnings),
        )

    analysistest.fail(
        env,
        "Expected warning '{}' was not emitted{}".format(
            expected,
            found_warnings_msg,
        ),
    )

def find_action(env, mnemonic):
    """Finds the first action with the given mnemonic in the target under test.

    This generates an analysis test failure if no action was found.

    Args:
        env: The analysis test environment.
        mnemonic: The mnemonic to find.

    Returns:
        The first action matching the mnemonic, or `None` if none was found.
    """
    actions = analysistest.target_actions(env)
    for action in actions:
        if action.mnemonic == mnemonic:
            return action

    analysistest.fail(env, "No '{}' action found".format(mnemonic))
    return None

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
