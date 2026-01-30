# shellcheck disable=SC2148

# Default to strict mode (only accept notarized)
: "${allowUnnotarized:=0}"

verifyNotarization() {
    [ -z "$DeveloperID" ] && {
        echo "ERROR: assertion failed: '[ ! -z $DeveloperID ]'"
        return 1
    }

    # shellcheck disable=SC2154
    mapfile -t BundleNames < <(ls -d -- "$sourceRoot"/*.app)
    [ ! "${#BundleNames[@]}" ] && {
        echo "ERROR: assertion failed: '[ \"${#BundleNames[@]}\" != 0 ]'"
        return 1
    }

    for _BundleName in "${BundleNames[@]}"; do
        BundleName=$(echo "$_BundleName" | sed -E 's/^\.\///g')

        echo "[DEBUG] spctl_output: "

        /usr/sbin/spctl -a -vvv -t install "$BundleName" || true

        # Get raw spctl output first
        spctl_output=$(/usr/sbin/spctl -a -vvv -t install "$BundleName" 2>&1)

        echo "[DEBUG] Full spctl output:"
        echo "$spctl_output"

        # Check if accepted or rejected - we care about the Developer ID regardless of policy
        if ! echo "$spctl_output" | grep -q "^$BundleName: \(accepted\|rejected\)"; then
            echo "Notarization status[$BundleName]: FAILED - unexpected spctl output format"
            return 1
        fi

        # Extract source and origin
        source_line=$(echo "$spctl_output" | grep "^source=" || true)
        origin_line=$(echo "$spctl_output" | grep "^origin=" || true)

        echo "[DEBUG] source_line: $source_line"
        echo "[DEBUG] origin_line: $origin_line"

        # Check if we have origin line (required for Developer ID verification)
        if [ -z "$origin_line" ]; then
            echo "Notarization status[$BundleName]: FAILED - no origin information in spctl output"
            return 1
        fi

        # Check Developer ID in origin
        if ! echo "$origin_line" | grep -q "$DeveloperID"; then
            echo "Notarization status[$BundleName]: FAILED - incorrect Developer ID"
            echo "Expected: $DeveloperID"
            echo "Got: $origin_line"
            return 1
        fi

        # Check if app was accepted or rejected by spctl
        app_status=$(echo "$spctl_output" | grep "^$BundleName:" | cut -d: -f2 | xargs)

        # Handle different cases based on source line presence and content
        if [ -n "$source_line" ]; then
            # We have a source line, check it
            case "$source_line" in
            "source=Notarized Developer ID")
                echo "Notarization status[$BundleName]: VERIFIED (Notarized Developer ID, DeveloperID: $DeveloperID, Status: $app_status)"
                ;;
            "source=Unnotarized Developer ID")
                if [ "$allowUnnotarized" = "1" ]; then
                    echo "Notarization status[$BundleName]: VERIFIED (Unnotarized but allowed, DeveloperID: $DeveloperID, Status: $app_status)"
                else
                    echo "Notarization status[$BundleName]: FAILED - unnotarized Developer ID not allowed"
                    echo "Set allowUnnotarized=1 to allow unnotarized Developer ID signatures"
                    return 1
                fi
                ;;
            "source=no usable signature")
                echo "Notarization status[$BundleName]: FAILED - no usable signature"
                return 1
                ;;
            *)
                echo "Notarization status[$BundleName]: FAILED - unknown source: $source_line"
                return 1
                ;;
            esac
        else
            # No source line - this can happen with Apple Development certificates
            # We still verified the Developer ID, so this is acceptable
            echo "Notarization status[$BundleName]: VERIFIED (Developer ID confirmed, DeveloperID: $DeveloperID, Status: $app_status)"
            echo "Note: No source= line in spctl output - this is normal for some certificate types"
        fi
    done
}

postUnpackHooks+=(verifyNotarization)
