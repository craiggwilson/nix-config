let
  remotes = [
    {
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }
  ];
in
{
  config.substrate.modules.services.flatpak = {
    tags = [ "flatpaks" ];
    nixos =
      { config, inputs, ... }:
      {
        imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

        hdwlinux.programs.flatpaks = [ "com.github.tchx84.Flatseal" ];

        xdg.portal.enable = true;

        services.flatpak = {
          inherit remotes;
          enable = true;
          packages = config.hdwlinux.programs.flatpaks;
          update.auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };
      };
    homeManager =
      {
        config,
        inputs,
        ...
      }:
      {
        imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

        services.flatpak = {
          inherit remotes;
          enable = true;
          packages = config.hdwlinux.programs.flatpaks;
          update.auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };

        xdg.systemDirs.data = [ "$XDG_DATA_HOME/flatpak/exports/share" ];
      };
  };
}
