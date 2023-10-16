{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.aws;
in
{
  options.hdwlinux.packages.aws = with types; {
    enable = mkBoolOpt false "Whether or not to enable aws.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        awscli2
    ];
  };
}

