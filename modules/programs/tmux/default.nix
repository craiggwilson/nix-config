{
  config.substrate.modules.programs.tmux = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        programs.tmux = {
          enable = true;
          shell = "${pkgs.zsh}/bin/zsh";
          terminal = "tmux-256color";
          historyLimit = 10000;
          escapeTime = 0;
          keyMode = "vi";
          mouse = true;
        };
      };
  };
}
