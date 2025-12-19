{ inputs, ... }:
{
  config.substrate.modules.programs.spotify = {
    tags = [ "audio" "gui" ];

    homeManager =
      { pkgs, ... }:
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        imports = [ inputs.spicetify-nix.homeManagerModules.default ];

        programs.spicetify = {
          enable = true;
          theme = spicePkgs.themes.catppuccin;
          colorScheme = "mocha";

          enabledExtensions = with spicePkgs.extensions; [
            adblock
            shuffle
          ];
        };
      };
  };
}

