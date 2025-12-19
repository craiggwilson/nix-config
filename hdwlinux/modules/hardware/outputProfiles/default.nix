{ lib, ... }:
let
  outputType = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this output is enabled.";
      };
      execs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Commands to execute for this output.";
      };
      position = lib.mkOption {
        type = lib.types.str;
        default = "0,0";
        description = "Position of this output (x,y).";
      };
      transform = lib.mkOption {
        type = lib.types.str;
        default = "normal";
        description = "Transform to apply.";
      };
      workspaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Workspaces to assign to this output.";
      };
    };
  };

  outputProfileType = lib.types.submodule {
    options = {
      execs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Commands to execute when this profile is activated.";
      };
      outputs = lib.mkOption {
        type = lib.types.attrsOf outputType;
        default = { };
        description = "Output configurations for this profile.";
      };
    };
  };

  outputProfilesOption = {
    options.hdwlinux.hardware.outputProfiles = lib.mkOption {
      description = "Output profile configurations for different monitor arrangements.";
      type = lib.types.attrsOf outputProfileType;
      default = { };
    };
  };
in
{
  config.substrate.types.output = outputType;
  config.substrate.types.outputProfile = outputProfileType;

  config.substrate.modules.hardware.outputProfiles = {
    nixos = outputProfilesOption;
    homeManager = outputProfilesOption;
  };
}
