{
  config.substrate.modules.programs.calibre = {
    provides = [ "programs:calibre" "gui" ];
    requires = [ "profiles:personal" ];
    tags = [
      "gui"
      "users:craig:personal"
    ];

    homeManager = {
      programs.calibre = {
        enable = true;
      };
    };
  };
}
