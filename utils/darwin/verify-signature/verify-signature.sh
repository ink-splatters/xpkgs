# shellcheck disable=SC2148

# https://raw.githubusercontent.com/xeji/nixpkgs/8f961de8df4d21fb53f9d4d97d34e20a02fad85d/pkgs/build-support/setup-hooks/verify-signature.sh
# Helper functions for verifying (detached) PGP signatures

# importPublicKey
# Add PGP public key contained in ${publicKey} to the keyring.
# All imported keys will be trusted by verifySig
_importPublicKey() {
    if [[ -z $signaturePublicKey || -z $fingerprint ]]; then
        echo "error: verifySignatureHook requires signaturePublicKey and fingerprint" >&2
        exit 1
    fi
    gpg -q --import "$signaturePublicKey" || exit 1

    local expectedFingerprint=
    expectedFingerprint=$(gpg --list-keys | tr -d ' \n' | grep -Eo '[0-9A-F]{40}')

    if [ "$expectedFingerprint" != "$fingerprint" ]; then
        echo "error: expectedFingerprint != fingerprint ($expectedFingerprint != $fingerprint)" >&2
        exit 1
    fi
}

verifySignature() {
    gpgv --keyring pubring.kbx "$1" "$2" || exit 1
}

# verifySrcSignature
# verify the signature $srcSignature for source file $src
verifySrcSignature() {
    _importPublicKey
    [ -z "$srcSignature" ] && return
    # shellcheck disable=SC2154
    verifySignature "$srcSignature" "$src"
}

# setup

# create temporary gpg homedir
GNUPGHOME=$(readlink -f .gnupgtmp)
export GNUPGHOME
rm -rf "$GNUPGHOME" # make sure it's a fresh empty dir
# shellcheck disable=SC2174
mkdir -p -m 700 "$GNUPGHOME"

# automatically check the signature before unpack if srcSignature is set
preUnpackHooks+=(verifySrcSignature)
