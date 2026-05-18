# Copyright 2026 The Bazel Authors. All rights reserved.
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

"""Providers used internally by the Apple platform support rules not meant for client use."""

visibility([
    "@build_bazel_apple_support//lib/...",
    "@build_bazel_apple_support//test/...",
])

def make_banned_init(*, preferred_public_factory = None, provider_name):
    """Generates a lambda with a fail(...) for providers to dictate preferred initializer patterns."""
    if preferred_public_factory:
        return lambda: fail("""
{provider} is a provider that must be initialized through apple_provider.{preferred_public_factory}
""".format(
            provider = provider_name,
            preferred_public_factory = preferred_public_factory,
        ))
    return lambda: fail("""
%s is not a provider that is intended to be publicly initialized.

Please file an issue with the Apple BUILD rules if you would like a public API for this provider.
""" % provider_name)

ApplePlatformInfo, new_appleplatforminfo = provider(
    doc = "Provides information for the currently selected Apple platforms.",
    fields = {
        "target_arch": """
`String` representing the selected target architecture or cpu type.
""",
        "target_build_config": """
'configuration' representing the selected target's build configuration.
""",
        "target_environment": """
`String` representing the selected target environment (e.g. "device", "simulator").
""",
        "target_os": """
`String` representing the selected Apple OS.
""",
        "platform": """
The native platform object (acting as a compatibility shim).
""",
    },
    init = make_banned_init(provider_name = "ApplePlatformInfo"),
)
