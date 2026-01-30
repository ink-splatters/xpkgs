{lib, ...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }:
    lib.mkIf pkgs.stdenv.isDarwin (let
      inherit (config.utils.darwin) verifyNotarizationHook;
    in {
      packages.ungoogled-chromium-macos = pkgs.callPackage ({
        fetchurl,
        stdenvNoCC,
        undmg,
      }: let
        meta = builtins.fromJSON (builtins.readFile ./meta-info.json);
      in
        stdenvNoCC.mkDerivation {
          pname = "ungoogled-chromium-macos";
          inherit (meta) version;

          src = fetchurl {
            inherit (meta) url sha256;
          };

          nativeBuildInputs = [undmg verifyNotarizationHook];

          sourceRoot = ".";
          DeveloperID = "B9A88FL5XJ";

          installPhase = ''
            runHook preInstall

            mkdir -p $out/Applications
            mv *.app $out/Applications

            runHook postInstall
          '';

          dontFixup = true;

          outputHashMode = "recursive";
          outputHash = "sha256-u4bON8d8ZF+gCg/4fFQKe4gw7jteMZKCD41cNHdJS4c=";

          meta = {
            description = "macOS packaging for ungoogled-chromium";
            homepage = "https://ungoogled-software.github.io/downloads/";
            license = lib.licenses.bsd3;
            platforms = lib.platforms.darwin;
            sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
          };
        }) {};
    });
}
