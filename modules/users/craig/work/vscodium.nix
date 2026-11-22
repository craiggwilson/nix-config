{
  config.substrate.modules.users.craig.work.vscodium = {
    tags = [
      "user:craig:work"
      "desktop"
      "profile:programming"
    ];

    homeManager =
      {
        config,
        host,
        lib,
        pkgs,
        ...
      }:
      let
        shared = import ../../../programs/vscodium/_lib.nix {
          inherit
            config
            host
            lib
            pkgs
            ;
        };
        mmsProfile = shared.mkProfile [
          shared.layers.javaLayer
          shared.layers.goLayer
          shared.layers.bazelLayer
        ];
      in
      lib.mkMerge [
        {
          programs.vscodium.profiles.mms = {
            inherit (mmsProfile) enableMcpIntegration extensions keybindings;
          };
        }
        (shared.mkCanonicalSettings "mms" mmsProfile._settings)
      ];
  };
}
