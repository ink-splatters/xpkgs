{lib, ...}: {
  perSystem = {pkgs, ...}: {
    options.fetchers = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
    };
    config.fetchers = let
      inherit (pkgs) fetchurl;
    in
      {url, ...} @ args: {
        fetchpkg = {hash}:
          fetchurl {
            inherit url hash;
          };

        fetchsig = {hash}:
          fetchurl {
            url = args.url + ".asc";
            inherit hash;
          };

        fetchgpgkey = {
          fingerprint,
          hash,
        }:
          fetchurl {
            url = "https://keys.openpgp.org/vks/v1/by-fingerprint/${fingerprint}";
            inherit hash;
          };
      };
  };
}
