{
  inputs,
  pkgs,
  ...
}:

pkgs.mkShell {
  packages = [ inputs.panix.packages.${pkgs.system}.default ];
}
