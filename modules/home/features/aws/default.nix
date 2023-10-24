{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.aws;
in
{
  options.hdwlinux.features.aws = with types; {
    enable = mkBoolOpt false "Whether or not to enable aws.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    awscli2
  ];
}

