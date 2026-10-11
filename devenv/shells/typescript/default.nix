{
  substrate.devenv.shells.typescript =
    { pkgs, ... }:
    {
      # See the note in shells/go: PWD when the evaluation can see it, the literal
      # when it cannot, so pure evaluation of this flake is machine-independent.
      devenv.root =
        let
          pwd = builtins.getEnv "PWD";
        in
        if pwd != "" then pwd else "/home/craig";
      packages = with pkgs; [
        biome
        bun
      ];
    };
}
