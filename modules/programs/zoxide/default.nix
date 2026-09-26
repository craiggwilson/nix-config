{
  config.substrate.modules.programs.zoxide = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.zoxide ];

        hdwlinux.shell.zsh.initLines = [
          {
            prio = 100;
            text = "eval \"$(${pkgs.zoxide}/bin/zoxide init zsh )\"";
          }
        ];
        hdwlinux.shell.bash.initLines = [
          {
            prio = 580;
            text = "eval \"$(${pkgs.zoxide}/bin/zoxide init bash )\"";
          }
        ];
      };
  };
}
