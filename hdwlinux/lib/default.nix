# lib/default.nix - Consolidated hdwlinux library
#
# This file exports the hdwlinux library under the `hdwlinux` namespace.
# When used with bootstrap, this becomes available as `lib.hdwlinux`.
#
# Usage:
#   let
#     projectLib = import ./lib { inherit lib; };
#   in
#   # projectLib.hdwlinux contains all functions from file, module, options, theme, and types
{ lib }:
let
  # Import all sub-modules
  fileLib = import ./file { inherit lib; };
  moduleLib = import ./module { inherit lib; };
  optionsLib = import ./options { inherit lib; };
  themeLib = import ./theme { inherit lib; };
  typesLib = import ./types { inherit lib; };

  # Combine all sub-modules into the hdwlinux namespace
  hdwlinuxLib = {
    override-meta =
      meta: package:
      package.overrideAttrs (_: {
        inherit meta;
      });
  }
  // fileLib
  // moduleLib
  // optionsLib
  // themeLib
  // typesLib;
in
{
  hdwlinux = hdwlinuxLib;
}
