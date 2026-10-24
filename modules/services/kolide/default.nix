{
  config.substrate.modules.services.kolide = {
    tags = [
      "user:craig"
      "profile:work"
    ];
    nixos =
      { inputs, ... }:
      {
        imports = [ inputs.kolide-launcher.nixosModules.kolide-launcher ];

        services.kolide-launcher.enable = true;
      };
  };
}
