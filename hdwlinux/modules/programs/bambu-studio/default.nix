{
  config.substrate.modules.programs.bambu-studio = {
    tags = [
      "users:craig:personal"
    ];
    homeManager = {
      config.hdwlinux.programs.flatpaks = [ "com.bambulab.BambuStudio" ];
    };
  };
}
