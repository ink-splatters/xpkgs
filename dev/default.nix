{inputs, ...}: {
  imports = [
    inputs.git-hooks.flakeModule
    ./pre-commit.nix
    ./shell.nix
  ];

  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
