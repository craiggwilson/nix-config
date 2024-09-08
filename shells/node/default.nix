{
  pkgs,
  ...
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    bun
    nodePackages.prettier
    nodePackages.eslint
  ];
}
