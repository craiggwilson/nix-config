{
  # secretspec options exist on every configuration, so a module that declares
  # secrets without the core:security:secrets tag would silently produce a
  # manifest nothing resolves. Fail the build instead.
  config.substrate.modules.security.secrets-guard = {
    tags = [ "core:base" ];

    nixos =
      {
        config,
        hasTag,
        lib,
        ...
      }:
      let
        declared =
          builtins.attrNames config.secretspec.entries ++ builtins.attrNames config.secretspec.scopes;
      in
      {
        assertions = [
          {
            assertion = hasTag "core:security:secrets" || declared == [ ];
            message = "Secrets declared without the core:security:secrets tag: ${lib.concatStringsSep ", " declared}. Tag the declaring module with core:security:secrets.";
          }
        ];
      };

    homeManager =
      {
        config,
        hasTag,
        lib,
        ...
      }:
      let
        declared =
          builtins.attrNames config.secretspec.entries ++ builtins.attrNames config.secretspec.scopes;
      in
      {
        assertions = [
          {
            assertion = hasTag "core:security:secrets" || declared == [ ];
            message = "Secrets declared without the core:security:secrets tag: ${lib.concatStringsSep ", " declared}. Tag the declaring module with core:security:secrets.";
          }
        ];
      };
  };
}
