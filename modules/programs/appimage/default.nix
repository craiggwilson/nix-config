{
  config.substrate.modules.programs.appimage = {
    tags = [ "desktop" ];
    nixos = {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
  };
}
