{
  config.substrate.modules.services.kolide = {
    provides = [ "services:kolide" "profiles:work" ];
    tags = [ "users:craig:work" ];
    nixos =
      { inputs, ... }:
      {
        imports = [ inputs.kolide-launcher.nixosModules.kolide-launcher ];

        services.kolide-launcher.enable = true;
      };
  };
}
