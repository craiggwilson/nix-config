{
  config.substrate.modules.services.kolide = {
    tags = [ "role:managed-endpoint" ];
    nixos =
      { inputs, ... }:
      {
        imports = [ inputs.kolide-launcher.nixosModules.kolide-launcher ];

        services.kolide-launcher.enable = true;
      };
  };
}
