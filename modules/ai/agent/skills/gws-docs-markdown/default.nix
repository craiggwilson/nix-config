{
  config.substrate.modules.ai.agent.skills.gws-docs-markdown = {
    tags = [ "ai:agent" ];

    homeManager =
      { pkgs, ... }:
      let
        python = pkgs.python3.withPackages (
          ps: [
            ps.markdown-it-py
            ps.mdit-py-plugins
            ps.pyyaml
          ]
        );
      in
      {
        hdwlinux.ai.agent.skills.gws-docs-markdown = pkgs.runCommand "gws-docs-markdown-skill" { } ''
          mkdir -p $out/bin
          cp -r ${./skill}/* $out/

          cat > $out/bin/md2gdoc <<WRAPPER
          #!${pkgs.bash}/bin/bash
          exec ${python}/bin/python3 $out/md2gdoc.py "\$@"
          WRAPPER
          chmod +x $out/bin/md2gdoc

          # Replace $MD2GDOC token with the absolute binary path so the agent
          # never needs md2gdoc on PATH.
          ${pkgs.gnused}/bin/sed -i "s|\$MD2GDOC|$out/bin/md2gdoc|g" $out/SKILL.md
        '';
      };
  };
}
