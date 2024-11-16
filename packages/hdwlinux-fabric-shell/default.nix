{
  python3Packages,
  gtk3,
  cairo,
  gobject-introspection,
  wrapGAppsHook3,
  ...
}:

python3Packages.buildPythonApplication {
  pname = "fabric-shell";
  version = "0.0.1";
  pyproject = true;

  src = ./.;

  nativeBuildInputs = [
    wrapGAppsHook3
    gtk3
    gobject-introspection
    cairo
  ];

  dependencies = with python3Packages; [ python-fabric ];
  doCheck = false;
  dontWrapGApps = true;

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  meta = {
    description = "Shell using fabric for hdwlinux";
  };
}
