{
  config.substrate.modules.programs.appimage = {
    provides = [ "hardware:storage" ];
    nixos = {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
  };
}
