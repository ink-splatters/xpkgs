{
  description = "Dependencies for development purposes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks = {
      url = "github:ink-splatters/git-hooks.nix?ref=shfmt-options";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # TODO: doesn't make sense while git-hooks.nix is overridden
  # nixConfig = {
  #   extra-substituters = [
  #     "https://pre-commit-hooks.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
  #   ];
  # };

  outputs = _: {};
}
