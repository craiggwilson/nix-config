{
  config.substrate.modules.programs.bambu-studio = {
    tags = [ "profile:3d-printing" ];
    homeManager = {
      config.hdwlinux.programs.flatpaks = [ "com.bambulab.BambuStudio" ];
    };
  };
}
