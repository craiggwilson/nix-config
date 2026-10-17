{
  config.substrate.modules.programs.bambu-studio = {
    provides = [
      "programs:bambu-studio"
      "profiles:personal"
    ];
    homeManager = {
      config.hdwlinux.programs.flatpaks = [ "com.bambulab.BambuStudio" ];
    };
  };
}
