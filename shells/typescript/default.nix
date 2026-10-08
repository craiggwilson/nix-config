{
  substrate.shells.publish.typescript =
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
