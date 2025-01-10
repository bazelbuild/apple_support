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

"""Providers used by the Xcode build rules and their clients."""

visibility("public")

# TODO: b/311385128 - Migrate the native implementation here.
XcodeVersionInfo = apple_common.XcodeVersionConfig

XcodeSdkVariantInfo = provider(
    doc = """\
        Contains information about a specific SDK that is included in a version
        of Xcode.
        """,
    fields = {
        "archs": """\
            `list[str]`. The CPU architectures that are valid target
            architectures when building with this SDK.
            """,
        "build_version": """\
            `str`. The alpha-numeric build version component of the SDK. This is
            most often used to distinguish between different beta releases of
            the same SDK.
            """,
        "clangrt_name": """\
            `str`. The platform-specific component of the name of the clang-rt
            built-in libraries that should be linked into binaries when using
            features that require them, such as sanitizers.
            """,
        "device_families": """\
            `dict[str, str]`. The device families that are supported when
            compiling resources with this SDK. Each key in the dictionary is the
            name of a device family as it appears on the command line of
            resource processing tools, and the corresponding value is the
            numeric identifier used when referencing the device family in the
            `UIDeviceFamily` key of a bundle's `Info.plist` file.
            """,
        "llvm_triple_environment": """\
            `str`. The environment component of the LLVM triple that is used to
            compile code when building with this SDK. May be the empty string
            for device builds or platforms that do not use an environment
            component, like macOS.
            """,
        "llvm_triple_os": """\
            `str`. The operating system component of the LLVM triple that is
            used to compile code when building with this SDK.
            """,
        "llvm_triple_vendor": """\
            `str`. The vendor component of the LLVM triple that is used to
            compile code when building with this SDK.
            """,
        "maximum_supported_os_version": """\
            `apple_common.dotted_version`. The highest operating system version
            that is supported when building with this SDK.
            """,
        "minimum_supported_os_version": """\
            `apple_common.dotted_version`. The lowest operating system version
            that is supported when building with this SDK.
            """,
        "minimum_swift_concurrency_in_os_version": """\
            `apple_common.dotted_version`. The lowest operating system version
            for this platform in which the Swift concurrency runtime is included
            in the operating system. Bundles that are built for this OS version
            or higher do not need to include the concurrency runtime for
            back-deployment.
            """,
        "minimum_swift_in_os_version": """\
            `apple_common.dotted_version`. The lowest operating system version
            for this platform in which the Swift runtime (except for
            concurrency) is included in the operating system. Bundles that are
            built for this OS version or higher do not need to include the
            Swift runtime for back-deployment.
            """,
        "platform_directory_name": """\
            `str`. The name of the `.platform` and `.sdk` directories that
            contain the files for this SDK.
            """,
        "platform_name": """\
            `str`. The name of the platform that this SDK represents, in the
            form used when writing the platform name into a bundle's
            `Info.plist` file.
            """,
        "resources_platform_name": """\
            `str`. The name of the platform that this SDK represents, in the
            form used when passing it to resource compiling tools. This is
            typically the same as `platform_name`, but may differ for some SDKs.
            """,
        "version": """\
            `apple_common.dotted_version`. The full version string for this SDK,
            which is of the form `<major>.<minor>.<patch>.<build>` (where the
            fourth component is the same as the `build_version` attribute).
            """,
    },
)
