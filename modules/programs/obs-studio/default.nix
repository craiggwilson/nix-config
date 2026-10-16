{
  config.substrate.modules.programs.obs-studio = {
    provides = [ "programs:obs-studio" "video:production" ];
    requires = [ "gui" ];
    tags = [
      "gui"
      "video:production"
    ];

    homeManager =
      { pkgs, ... }:
      {
        programs.obs-studio = {
          enable = true;
          plugins = with pkgs.obs-studio-plugins; [
            droidcam-obs
            obs-pipewire-audio-capture
            wlrobs
          ];
        };
      };
  };
}
