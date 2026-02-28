{
  pkgs,
  ...
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    bun
  ];
}
