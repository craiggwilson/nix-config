# Render per-user (host, user) evaluations into a NixOS module. One module
# per host, evaluated once per user that the host assigns.
#
# Output mechanisms, all native:
#   packages    -> users.users.<name>.packages
#   files       -> per-user link script, run by an activation unit
#   environment -> linked environment.d file + systemctl --user set-environment
#   services    -> systemd.user.services with unitConfig.ConditionUser,
#                  automatically ordered after the activation unit
#
# Units are installed globally (NixOS only has global systemd.user.*) but are
# inert for other users thanks to ConditionUser.
#
# Note: takes pkgs as a plain argument (not a module lambda) because the
# result is spliced directly into mkMerge. Per-user derivations use the host
# pkgs; usercfg.system is cross-checkable if we ever build cross-system.
{
  lib,
  inputs,
  slib,
  hostcfg,
  allOverlays,
  pkgs,
  usercfgOf,
}:
let
  renderUser = userKey: {
    # users/systemd appear only as option path prefixes; no module args needed
    # beyond the closure's pkgs.
    ...
  }:
    let
      usercfg = usercfgOf userKey;
      cfg = import ./eval.nix {
        inherit
          lib
          inputs
          slib
          hostcfg
          usercfg
          allOverlays
          ;
      };

      username = usercfg.name;
      unitName = "hdwlinux-" + builtins.replaceStrings [ "@" ] [ "-" ] userKey;
      envFileName = "99-${unitName}.conf";
      envTarget = "${cfg.homeDirectory}/.config/environment.d/${envFileName}";

      q = lib.escapeShellArg;
      inherit (lib)
        concatStringsSep
        filterAttrs
        mapAttrs
        mapAttrsToList
        ;
      inherit (builtins) dirOf;

      linkLine = rel: entry:
        if entry.source == null then
          throw "perUser file '${rel}' for ${userKey}: exactly one of 'source' or 'text' must be set"
        else
          ''
            target=${q "${cfg.homeDirectory}/${rel}"}
            mkdir -p ${q (dirOf "${cfg.homeDirectory}/${rel}")}
            if [ -e "$target" ] && [ ! -L "$target" ]; then mv -- "$target" "$target.pre-per-user-backup"; fi
            ln -sfn ${q (toString entry.source)} "$target"
          '';

      setEnvLine = k: v: ''
        ${pkgs.systemd}/bin/systemctl --user set-environment ${q "${k}=${v}"} || true
      '';

      environmentFile = pkgs.writeText envFileName (
        concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${q v}") cfg.env)
      );

      activationScript = ''
        ${concatStringsSep "\n" (mapAttrsToList linkLine cfg.files)}

        mkdir -p ${q (dirOf envTarget)}
        if [ -e ${q envTarget} ] && [ ! -L ${q envTarget} ]; then mv -- ${q envTarget} ${q "${envTarget}.pre-per-user-backup"}; fi
        ln -sfn ${q environmentFile} ${q envTarget}

        ${concatStringsSep "\n" (mapAttrsToList setEnvLine cfg.env)}
      '';

      renderService =
        name: svc:
        {
          description = svc.description;
          path = svc.path;
          wantedBy = svc.wantedBy;
          after = svc.after ++ [ "${unitName}.service" ];
          wants = [ "${unitName}.service" ];
          before = svc.before;
          inherit (svc)
            script
            environment
            ;
          unitConfig = svc.unitConfig // {
            ConditionUser = username;
          };
          serviceConfig = svc.serviceConfig // {
            Type = svc.serviceConfig.Type or "simple";
          };
        };
    in
    {
      assertions = [
        {
          assertion = !(cfg.files ? ".config/environment.d/${envFileName}");
          message = "perUser file '.config/environment.d/${envFileName}' collides with the environment.d link";
        }
        {
          assertion = !(cfg.services ? ${unitName});
          message = "perUser service name '${unitName}' collides with the activation unit";
        }
      ];

      users.users.${username}.packages = cfg.packages;

      systemd.user.services = ({
        ${unitName} = {
          description = "hdwlinux per-user config activation for ${userKey}";
          wantedBy = [ "basic.target" ];
          unitConfig.ConditionUser = username;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = activationScript;
        };
      }
      // mapAttrs renderService (filterAttrs (_: svc: svc.enable) cfg.services));
    };
in
# Functions inside mkMerge are rejected by the module system; nested modules
# ride in imports instead.
{ imports = map renderUser hostcfg.users; }
