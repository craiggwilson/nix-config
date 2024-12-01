{
  stdenvNoCC,
  inputs,
  pkgs,
  system,
}:
stdenvNoCC.mkDerivation rec {
  name = "hdwshell";
  src = ./src;

  nativeBuildInputs = [
    inputs.ags.packages.${system}.default
    pkgs.wrapGAppsHook
    pkgs.gobject-introspection
  ];

  buildInputs = with inputs.astal.packages.${system}; [
    astal3
    io
    # any other package
    brightnessctl
  ];

  installPhase = ''
    mkdir -p $out/bin
    ags bundle app.ts $out/bin/${name}
  '';

  meta = {
    mainProgram = name;
    description = "HDWShell - the shell for HDWLinux";
  };
}
