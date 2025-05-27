# Copyright 2025 The Bazel Authors. All rights reserved.
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

"""Implementation of the `xcode_sdk_variant` build rule."""

load(
    "@build_bazel_apple_support//xcode:providers.bzl",
    "XcodeSdkVariantInfo",
)

visibility("public")

def _xcode_sdk_variant_impl(ctx):
    def dotted_version_or_none(str):
        if not str:
            return None
        return apple_common.dotted_version(str)

    return [
        XcodeSdkVariantInfo(
            archs = ctx.attr.archs,
            build_version = ctx.attr.build_version,
            clangrt_name = ctx.attr.clangrt_name,
            device_families = ctx.attr.device_families,
            llvm_triple_environment = ctx.attr.llvm_triple_environment,
            llvm_triple_os = ctx.attr.llvm_triple_os,
            llvm_triple_vendor = ctx.attr.llvm_triple_vendor,
            maximum_supported_os_version = dotted_version_or_none(
                ctx.attr.maximum_supported_os_version,
            ),
            minimum_supported_os_version = dotted_version_or_none(
                ctx.attr.minimum_supported_os_version,
            ),
            minimum_swift_concurrency_in_os_version = dotted_version_or_none(
                ctx.attr.minimum_swift_concurrency_in_os_version,
            ),
            minimum_swift_in_os_version = dotted_version_or_none(
                ctx.attr.minimum_swift_in_os_version,
            ),
            platform_directory_name = ctx.attr.platform_directory_name,
            platform_name = ctx.attr.platform_name,
            resources_platform_name = ctx.attr.resources_platform_name,
            version = dotted_version_or_none(ctx.attr.version),
        ),
    ]

xcode_sdk_variant = rule(
    implementation = _xcode_sdk_variant_impl,
    attrs = {
        "archs": attr.string_list(
            doc = """\
                The CPU architectures that are valid target architectures when
                building with this SDK.
                """,
        ),
        "build_version": attr.string(
            doc = """\
                The alpha-numeric build version component of the SDK. This is
                most often used to distinguish between different beta releases
                of the same SDK.
                """,
        ),
        "clangrt_name": attr.string(
            doc = """\
                The platform-specific component of the name of the clang-rt
                built-in libraries that should be linked into binaries when
                using features that require them, such as sanitizers.
            """,
        ),
        "device_families": attr.string_dict(
            doc = """\
                The device families that are supported when compiling resources
                with this SDK. Each key in the dictionary is the name of a
                device family as it appears on the command line of resource
                processing tools, and the corresponding value is the numeric
                identifier used when referencing the device family in the
                `UIDeviceFamily` key of a bundle's `Info.plist` file.
                """,
        ),
        "llvm_triple_environment": attr.string(
            doc = """\
                The environment component of the LLVM triple that is used to
                compile code when building with this SDK.
                """,
        ),
        "llvm_triple_os": attr.string(
            doc = """\
                The operating system component of the LLVM triple that is used
                to compile code when building with this SDK.
                """,
        ),
        "llvm_triple_vendor": attr.string(
            doc = """\
                The vendor component of the LLVM triple that is used to compile
                code when building with this SDK.
                """,
        ),
        "maximum_supported_os_version": attr.string(
            doc = """\
                The highest operating system version that is supported when
                building with this SDK.
                """,
        ),
        "minimum_supported_os_version": attr.string(
            doc = """\
                The lowest operating system version that is supported when
                building with this SDK.
                """,
        ),
        "minimum_swift_concurrency_in_os_version": attr.string(
            doc = """\
                The lowest operating system version for this platform in which
                the Swift concurrency runtime is included in the operating
                system. Bundles that are built for this OS version or higher
                do not need to include the concurrency runtime for
                back-deployment.
                """,
        ),
        "minimum_swift_in_os_version": attr.string(
            doc = """\
                The lowest operating system version for this platform in which
                the Swift runtime (except for concurrency) is included in the
                operating system. Bundles that are built for this OS version or
                higher do not need to include the Swift runtime for
                back-deployment.
                """,
        ),
        "platform_directory_name": attr.string(
            doc = """\
                The name of the `.platform` and `.sdk` directories that contain
                the files for this SDK.
                """,
        ),
        "platform_name": attr.string(
            doc = """\
                The name of the platform that this SDK represents, in the
                form used when writing the platform name into a bundle's
                `Info.plist` file.
                """,
        ),
        "resources_platform_name": attr.string(
            doc = """\
                The name of the platform that this SDK represents, in the
                form used when passing it to resource compiling tools. This is
                typically the same as `platform_name`, but may differ for some
                SDKs.
                """,
        ),
        "version": attr.string(
            doc = """\
                The full version string for this SDK, which is of the form
                `<major>.<minor>.<patch>`.
                """,
        ),
    },
)
