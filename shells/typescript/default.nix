{
  pkgs,
  ...
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    biome
    bun
  ];
}
