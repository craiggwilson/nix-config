{
  config.substrate.modules.programs.calibre = {
    provides = [ "gui" ];
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
