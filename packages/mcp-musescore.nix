{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation {
  pname = "mcp-musescore";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "craiggwilson";
    repo = "mcp-musescore";
    rev = "f757263e9885f559d7b3fd70735121a991bce7d8";
    hash = "sha256-6g4v9g+YEoC1r4l241WJnayFhz4MccoHnv0r3mA8TYM=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mcp-musescore $out/bin $out/share/musescore-plugins

    cp -r $src/src $out/share/mcp-musescore/
    cp $src/server.py $out/share/mcp-musescore/
    cp $src/musescore-mcp-websocket.qml $out/share/musescore-plugins/

    makeWrapper ${
      pkgs.python3.withPackages (ps: [
        ps.mcp
        ps.websockets
      ])
    }/bin/python $out/bin/mcp-musescore \
      --add-flags "$out/share/mcp-musescore/server.py" \
      --set PYTHONPATH "$out/share/mcp-musescore"

    runHook postInstall
  '';

  meta = {
    description = "MCP server providing programmatic control over MuseScore via WebSocket";
    homepage = "https://github.com/craiggwilson/mcp-musescore";
    license = lib.licenses.mit;
    mainProgram = "mcp-musescore";
    platforms = lib.platforms.linux;
  };
}
