{
  pkgs,
  ...
}:

pkgs.buildGoModule {
  name = "fern";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/10gen/fern";
    ref = "v2.24.0";
    rev = "37225cc9146b55dfc7d001e414a111f857d356f5";
  };

  vendorHash = "sha256-9UhIUpr/D7gHSQ7uaeLP5AsineVM4CX4ydwzcISpH9w=";

  subPackages = [ "." ];

  meta = {
    mainProgram = "fern";
    description = "Fern - Build and run services within a multi-process ecosystem.";
    homepage = "https://github.com/10gen/fern";
  };
}
