{lib, ...}: {
  perSystem = {pkgs, ...}: {
    options.utils.darwin.app-install-phase = lib.mkOption {
      type = lib.types.attrs;
    };

    config.utils.darwin.app-install-phase = lib.mkIf pkgs.stdenv.isDarwin {
      # 7zz creates files for each xattr it experiences, and seems to do it
      # only in case of APFS file system.
      #
      # Extra files present in .app bundles lead to signature check failures,
      # therefore we remove those files here
      unpackPhase = ''
        runHook preUnpack

        7zz -snld x $src

        find . -name '*:com.apple.*' -exec rm -f {} \;

        runHook postUnpack
      '';
    };
  };
}
