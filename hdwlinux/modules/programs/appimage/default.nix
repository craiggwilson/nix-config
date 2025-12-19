{
  config.substrate.modules.programs.appimage = {
    nixos = {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
  };
}

