{
  pkgs,
  ...
}:

pkgs.buildGoModule {
  name = "fern";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/10gen/fern";
    ref = "v2.9.1";
    rev = "eded50e329d78832b4efc3f6d7b739254edac3a3";
  };

  vendorHash = "sha256-7/HnZ3DIINkJqwRDnMomP8t7Rgj5h/ikHvjxDWxjI5A=";

  subPackages = [ "." ];

  meta = {
    mainProgram = "fern";
    description = "Fern - Build and run services within a multi-process ecosystem.";
    homepage = "https://github.com/10gen/fern";
  };
}

