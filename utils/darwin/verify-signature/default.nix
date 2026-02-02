{lib, ...}: {
  perSystem = {pkgs, ...}: {
    options.utils.darwin.verifySignatureHook = lib.mkOption {
      type = lib.types.package;
    };
    config.utils.darwin.verifySignatureHook = lib.mkIf pkgs.stdenv.isDarwin (
      pkgs.makeSetupHook {
        name = "verify-signature-hook";
        propagatedBuildInputs = with pkgs; [gnupg unzip];
      }
      ./verify-signature.sh
    );
  };
}
