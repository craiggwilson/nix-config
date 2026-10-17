{
  config.substrate.modules.programs.obs-studio = {
    provides = [
      "programs:obs-studio"
      "video:production"
    ];
    requires = [ "gui" ];
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
