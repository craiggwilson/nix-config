{ lib, ... }:
with lib; rec {
  mkOpt = type: default: description: mkOption { inherit type default description; };

  mkBoolOpt = mkOpt types.bool;
  mkStrOpt = mkOpt types.str;
  mkNullStrOpt = mkOpt (types.nullOr types.str);
}