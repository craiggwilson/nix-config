let
  outputProfiles = {
    raeford-docked = {
      outputs = {
        office-main = {
          enable = true;
          position = "0,1440";
          workspaces = [ "3" ];
        };
        office-top = {
          enable = true;
          position = "1290,0";
          workspaces = [ "1" ];
        };
        portable = {
          enable = true;
          position = "1000,2880";
          workspaces = [ "2" ];
        };
        laptop = {
          enable = false;
        };
      };
    };
  };
in
{
  config.substrate.modules.locations.raeford.outputProfiles = {
    tags = [ "raeford" ];

    nixos = {
      hdwlinux.hardware.outputProfiles = outputProfiles;
    };

    homeManager = {
      hdwlinux.hardware.outputProfiles = outputProfiles;
    };
  };
}

