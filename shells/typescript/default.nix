{
  substrate.publish.devShells.typescript =
    {
      pkgs,
      ...
    }:

    pkgs.mkShell {
      buildInputs = with pkgs; [
        biome
        bun
      ];
    };
}
