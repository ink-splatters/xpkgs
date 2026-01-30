{lib, ...}: {
  perSystem = {pkgs, ...}: {
    options.utils.darwin.verifyNotarizationHook = lib.mkOption {
      type = lib.types.package;
    };
    config.utils.darwin.verifyNotarizationHook = (pkgs.makeSetupHook {
        name = "verify-notarization-hook";
      }
      ./verify-notarization.sh).overrideAttrs {
      sandboxProfile = ''
        (allow process-exec
          (literal "/usr/sbin/spctl")
          (with no-sandbox))
      '';
    };
  };
}
