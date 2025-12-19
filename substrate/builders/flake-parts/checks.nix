{
  lib,
  config,
  ...
}:
let
  allValidations = config.substrate.settings.checks;
  allValid = lib.all (v: v.valid || (v.warn or false)) allValidations;

  summary =
    let
      passed = lib.filter (v: v.valid) allValidations;
      warnings = lib.filter (v: !v.valid && (v.warn or false)) allValidations;
      failed = lib.filter (v: !v.valid && !(v.warn or false)) allValidations;
    in
    ''
      Substrate Configuration Validation
      ===================================
      Checks: ${toString (lib.length allValidations)}
      Passed: ${toString (lib.length passed)}
      Warnings: ${toString (lib.length warnings)}
      Failed: ${toString (lib.length failed)}

      ${lib.concatMapStringsSep "\n" (
        v:
        let
          status =
            if v.valid then
              "PASS"
            else if v.warn or false then
              "WARN"
            else
              "FAIL";
        in
        "${v.name}: ${v.message}"
      ) allValidations}
    '';

  evalWarnings =
    let
      warnings = lib.filter (v: !v.valid && (v.warn or false)) allValidations;
    in
    lib.concatMapStrings (v: lib.warn "substrate: ${v.name}: ${v.message}" "") warnings;

  evalErrors = lib.filter (v: !v.valid && !(v.warn or false)) allValidations;
  hasErrors = evalErrors != [ ];
  errorMessages = lib.concatMapStringsSep "\n" (v: "  - ${v.name}: ${v.message}") evalErrors;

  validated = builtins.seq evalWarnings (
    if hasErrors then
      throw ''
        Substrate configuration validation failed!
        ${errorMessages}
      ''
    else
      true
  );
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.substrate-config =
        assert validated;
        pkgs.runCommand "substrate-config-validation" { } ''
            echo "All substrate configuration checks passed!"
            cat <<'EOF'
          ${summary}
          EOF
            touch $out
        '';
    };
}
