{
  substrate.devenv.shells.hdwlinux =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      # See the note in shells/go: PWD when the evaluation can see it, the literal
      # when it cannot.
      devenv.root =
        let
          pwd = builtins.getEnv "PWD";
        in
        if pwd != "" then pwd else "/home/craig";
      packages = [ inputs.panix.packages.${pkgs.system}.default ];
    };
}
