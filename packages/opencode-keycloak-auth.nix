_:
{
  substrate.packages.opencode-keycloak-auth =
    { pkgs, ... }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "opencode-keycloak-auth";
      version = "1.0.0";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/opencode-keycloak-auth/-/opencode-keycloak-auth-1.0.0.tgz";
        hash = "sha256-0idWQvWL4fc6Mm1zzfCYB0NP8+NeLfdYxlVssc2QTp0=";
      };

      installPhase = ''
        pluginDir=$out/lib/node_modules/opencode-keycloak-auth
        mkdir -p "$pluginDir"
        cp -R ./* "$pluginDir/"

        # Keep the plugin reusable: the provider ID is the display identity instead
        # of a provider-specific integration name baked into the upstream bundle.
        substituteInPlace "$pluginDir/dist/index.js" \
          --replace-fail 'integration.name = INTEGRATION_NAME;' 'integration.name = id;' \
          --replace-fail 'name: "Keycloak",' 'name: id,'
      '';

      meta = {
        description = "OpenCode Keycloak OAuth plugin with dynamic provider naming";
        homepage = "https://www.npmjs.com/package/opencode-keycloak-auth";
        license = pkgs.lib.licenses.mit;
        platforms = pkgs.lib.platforms.unix;
      };
    };
}
