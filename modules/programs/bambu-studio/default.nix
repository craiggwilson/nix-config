{
  config.substrate.modules.programs.bambu-studio = {
    tags = [
      "profile:personal"
    ];
    homeManager = {
      config.hdwlinux.programs.flatpaks = [ "com.bambulab.BambuStudio" ];
    };
  };
}
