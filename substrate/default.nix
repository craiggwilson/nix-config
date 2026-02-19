let
  wrapBuilder =
    builder: args: module:
    let
      module' = {
        imports = [
          module
          ./core
        ];
      };
    in
    builder.build args module';
in
{
  build = {
    with-flake-parts = wrapBuilder (import ./builders/flake-parts/default.nix);
  };
  substrateModules = {
    home-manager = import ./extensions/home-manager;
    jail = import ./extensions/jail;
    nixos = import ./extensions/nixos;
    overlays = import ./extensions/overlays;
    packages = import ./extensions/packages;
    shells = import ./extensions/shells;
    tags = import ./extensions/tags;
    types = import ./extensions/types;
  };
}
