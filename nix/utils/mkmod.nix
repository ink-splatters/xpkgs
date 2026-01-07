path: {
  _util ? false,
  _name ? null,
  ...
} @ args: let
  # Use only builtins here (no lib available yet)
  basename = baseNameOf (toString path);
  name =
    if _name != null
    then _name
    else let
      len = builtins.stringLength basename;
      hasSuffix = builtins.substring (len - 4) 4 basename == ".nix";
    in
      if hasSuffix
      then builtins.substring 0 (len - 4) basename
      else basename;

  packageArgs = builtins.removeAttrs args ["_util" "_name"];
  hasPackageArgs = packageArgs != {};
in {
  # Return a flake-parts module
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    base = pkgs.callPackage path {};

    mod =
      if builtins.isFunction base
      then
        if hasPackageArgs
        then finalArgs: base (packageArgs // finalArgs)
        else base
      else base;
  in {
    options = lib.optionalAttrs _util {
      utils.${name} = lib.mkOption {
        type = lib.types.unspecified;
        description = "Utility loaded from ${toString path}";
      };
    };

    config =
      if _util
      then {utils.${name} = mod;}
      else {packages.${name} = mod;};
  };
}
