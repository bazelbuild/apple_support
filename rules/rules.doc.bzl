"""
Helper rules for Apple platforms
"""

load("//rules/private:apple_genrule.bzl", _apple_genrule = "apple_genrule")
load("//rules:universal_binary.bzl", _universal_binary = "universal_binary")

apple_genrule = _apple_genrule
universal_binary = _universal_binary
