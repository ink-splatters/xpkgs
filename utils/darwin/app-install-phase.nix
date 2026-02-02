{lib, ...}: {
  perSystem = {pkgs, ...}: {
    options.utils.darwin.app-install-phase = lib.mkOption {
      type = lib.types.attrs;
    };

    config.utils.darwin.app-install-phase = lib.mkIf pkgs.stdenv.isDarwin {
      installPhase = ''
        runHook preInstall

        mkdir -p $out/Applications
        mv *.app $out/Applications

        runHook postInstall
      '';

      dontFixup = true;
    };
  };
}
