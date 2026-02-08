{
  config.substrate.modules.ai.agent.skills.excalidraw-diagrams = {
    tags = [
      "ai:agent"
    ];

    homeManager =
      { pkgs, ... }:
      let
        python = pkgs.python3.withPackages (_ps: [ ]);
        nodejs = pkgs.nodejs;
      in
      {
        hdwlinux.ai.skills.excalidraw-diagrams = pkgs.runCommand "excalidraw-diagrams-skill" { } ''
          mkdir -p $out/bin
          cp -r ${./skill}/* $out/

          # Python wrapper
          cat > $out/bin/python <<WRAPPER
          #!${pkgs.bash}/bin/bash
          exec ${python}/bin/python3 "\$@"
          WRAPPER
          chmod +x $out/bin/python

          # Node.js wrapper
          cat > $out/bin/node <<WRAPPER
          #!${pkgs.bash}/bin/bash
          exec ${nodejs}/bin/node "\$@"
          WRAPPER
          chmod +x $out/bin/node

          # npm wrapper
          cat > $out/bin/npm <<WRAPPER
          #!${pkgs.bash}/bin/bash
          exec ${nodejs}/bin/npm "\$@"
          WRAPPER
          chmod +x $out/bin/npm

          # npx wrapper
          cat > $out/bin/npx <<WRAPPER
          #!${pkgs.bash}/bin/bash
          exec ${nodejs}/bin/npx "\$@"
          WRAPPER
          chmod +x $out/bin/npx
        '';
      };
  };
}
