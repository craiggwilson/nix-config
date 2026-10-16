{
  config.substrate.modules.programs.bambu-studio = {
    provides = [ "profiles:personal" ];
    tags = [
      "users:craig:personal"
    ];
    homeManager = {
      config.hdwlinux.programs.flatpaks = [ "com.bambulab.BambuStudio" ];
    };
  };
}
