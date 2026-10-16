{
  config.substrate.modules.programs.appimage = {
    provides = [ "programs:appimage" "hardware:storage" ];
    nixos = {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
  };
}
