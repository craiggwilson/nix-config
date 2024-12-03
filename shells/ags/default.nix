{
  inputs,
  pkgs,
  system,
  ...
}:

pkgs.mkShell {
  buildInputs = [
    # includes astal3 astal4 astal-io by default
    # list at https://github.com/Aylur/astal/blob/main/flake.nix
    (inputs.ags.packages.${system}.default.override {
      extraPackages = builtins.attrValues (
        builtins.removeAttrs inputs.astal.packages.${pkgs.system} [
          "cava"
          "docs"
        ]
      );
    })
  ];
}
