{
  config.substrate.modules.programs.ripgrep = {
    provides = [ "programming" ];
    tags = [ "programming" ];

    homeManager = {
      programs.ripgrep = {
        enable = true;
        arguments = [
          "--max-columns=150"
          "--max-columns-preview"
          "--smart-case"
        ];
      };
    };
  };
}
