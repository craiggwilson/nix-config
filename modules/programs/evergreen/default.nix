{
  config.substrate.modules.programs.evergreen = {
    tags = [
      "programming"
      "users:craig:work"
    ];

    homeManager =
      { config, pkgs, ... }:
      let
        configFile = "${config.home.homeDirectory}/.evergreen.yml";
      in
      {
        home.packages = [
          (pkgs.writeScriptBin "evergreen" ''
            ${pkgs.hdwlinux.evergreen}/bin/evergreen --config "${configFile}" "$@"
          '')
        ];

        hdwlinux.security.secrets = {
          entries.evergreenApiKey = {
            reference = "op://Work/evergreen/api-key";
            mode = "0600";
          };

          templates.evergreenConfig = {
            source = ./evergreen.yml;
            target = configFile;
            replacements = [
              {
                secretPath = config.hdwlinux.security.secrets.entries.evergreenApiKey.path;
                string = "@@API_KEY@@";
              }
            ];
          };
        };
      };
  };
}
