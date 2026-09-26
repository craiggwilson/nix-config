{
  config.substrate.modules.programs.jq = {
    tags = [ "programming" ];

    perUser = { pkgs, ... }: {
      packages = [ pkgs.jq ];
    };
  };
}

