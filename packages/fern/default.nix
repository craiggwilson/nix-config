{
  pkgs,
  ...
}:

pkgs.buildGoModule {
  name = "fern";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/10gen/fern";
    ref = "v2.4.0";
    rev = "f2b0374e1c8aa7e9cb709069ca01b80148d0cee9";
  };

  vendorHash = "sha256-TAILvmwHuV7LmKMUEtvPOpZQKw98lRCOXKn91VMv1Hg=";

  subPackages = [ "." ];

  meta = {
    mainProgram = "fern";
    description = "Fern - Build and run services within a multi-process ecosystem.";
    homepage = "https://github.com/10gen/fern";
  };
}
