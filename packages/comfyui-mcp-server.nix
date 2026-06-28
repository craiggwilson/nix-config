{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation {
  pname = "comfyui-mcp-server";
  version = "1.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "joenorton";
    repo = "comfyui-mcp-server";
    rev = "v1.1.1";
    hash = "sha256-nmhQjXWtiQORoZUxzM7ELJvrXBT63ALWx3T/u7gQlys=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/comfyui-mcp-server $out/bin

    cp -r $src/* $out/share/comfyui-mcp-server/

    makeWrapper ${pkgs.python3.withPackages (ps: with ps; [ mcp pillow requests ])}/bin/python $out/bin/comfyui-mcp-server \
      --add-flags "$out/share/comfyui-mcp-server/server.py" \
      --set PYTHONPATH "$out/share/comfyui-mcp-server"

    runHook postInstall
  '';

  meta = {
    description = "MCP server for local ComfyUI";
    homepage = "https://github.com/joenorton/comfyui-mcp-server";
    license = lib.licenses.asl20;
    mainProgram = "comfyui-mcp-server";
    platforms = lib.platforms.linux;
  };
}
