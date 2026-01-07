{
  perSystem = {
    pkgs,
    config,
    ...
  }: let
    inherit (config) pre-commit;
  in {
    devShells.default = pkgs.mkShell.override {stdenv = pkgs.stdenvNoCC;} {
      packages = [pkgs.mdformat] ++ pre-commit.settings.enabledPackages;

      shellHook = ''
        ${pre-commit.installationScript}
      '';
    };
  };
}
