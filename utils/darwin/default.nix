{...}: {
  imports = [
    ./7zz-unpack-phase.nix
    ./app-install-phase.nix
    ./verify-notarization
    ./verify-signature
  ];
}
