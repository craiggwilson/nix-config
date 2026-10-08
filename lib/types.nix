# Shared option types used across substrate modules.
#
# Each entry is a function of `lib` returning something usable directly as a
# `mkOption` type, so a module can do:
#
#   types = import ../../../lib/types.nix;
#   type = types.graphicsCard lib;
#
# These used to be published through substrate's now-removed `types` extension
# as `substrate.types.*`. Nothing else about them needed substrate, so they live
# here instead.
{
  # A file to fetch from a remote model repository.
  file =
    lib:
    lib.types.submodule (
      { config, ... }:
      {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "The filename.";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            description = "HuggingFace repository (org/name).";
          };
          sha256 = lib.mkOption {
            type = lib.types.str;
            description = "The hash of the file content.";
          };
          subdir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional subdirectory within the repo for split files.";
          };
          type = lib.mkOption {
            type = lib.types.enum [ "huggingface" ];
            default = "huggingface";
            description = "Source type for the file download. Extensible with new types.";
          };
          url = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            description = "Computed download URL built from the source type and its fields.";
          };
        };
        config = {
          url =
            "https://huggingface.co/${config.repo}/resolve/main"
            + lib.optionalString (config.subdir != null) "/split_files/${config.subdir}"
            + "/${config.name}?download=true";
        };
      }
    );

  # A PCI device identified by bus id and device path.
  pcicard =
    lib:
    lib.types.submodule {
      options = {
        busId = lib.mkOption {
          description = "The PCI bus id. You can find it using lspci.";
          type = lib.types.strMatching "([0-9a-f]{1,3}[\:][0-9a-f]{1,2}[\.][0-9a-f])?";
          example = "01:00.0";
          default = "";
        };
        path = lib.mkOption {
          description = "The path to the card.";
          type = lib.types.str;
          default = "";
        };
      };
    };

  # A graphics card: a PCI card plus the render path it exposes.
  graphicsCard =
    lib:
    lib.types.submodule {
      options = {
        busId = lib.mkOption {
          description = "The PCI bus id. You can find it using lspci.";
          type = lib.types.strMatching "([0-9a-f]{1,3}[\:][0-9a-f]{1,2}[\.][0-9a-f])?";
          example = "01:00.0";
          default = "";
        };
        path = lib.mkOption {
          description = "The path to the card.";
          type = lib.types.str;
          default = "";
        };
        render = lib.mkOption {
          description = "The render path to the card.";
          type = lib.types.str;
          default = "";
        };
      };
    };
}
