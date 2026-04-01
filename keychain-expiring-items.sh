#!/bin/sh
# Lists generic password keychain items whose "modified date + 1 year"
# is within the next N days (default: 30).
#
# macOS-only, using POSIX shell tools plus `security` and BSD `date`.

set -eu

DAYS="${1:-30}"
KEYCHAIN="${2:-$HOME/Library/Keychains/login.keychain-db}"

NOW_EPOCH=$(date -u +%s)
CUTOFF_EPOCH=$((NOW_EPOCH + DAYS * 86400))

security dump-keychain "$KEYCHAIN" 2>/dev/null |
awk '
BEGIN {
    RS = "keychain: \""
}

function extract_value(line, key,    prefix, value) {
    prefix = "\"" key "\"<blob>=\""
    if (index(line, prefix) == 1) {
        value = line
        sub("^\"" key "\"<blob>=\"", "", value)
        sub("\"$", "", value)
        return value
    }
    return ""
}

# Generic password items only
/class: "genp"/ {
    item = $0
    label = account = service = modified = ""

    n = split(item, lines, "\n")
    for (i = 1; i <= n; i++) {
        line = lines[i]

        if (label == "" && index(line, "\"labl\"<blob>=\"") == 1) {
            label = line
            sub(/^"labl"<blob>="/, "", label)
            sub(/"$/, "", label)
        } else if (account == "" && index(line, "\"acct\"<blob>=\"") == 1) {
            account = line
            sub(/^"acct"<blob>="/, "", account)
            sub(/"$/, "", account)
        } else if (service == "" && index(line, "\"svce\"<blob>=\"") == 1) {
            service = line
            sub(/^"svce"<blob>="/, "", service)
            sub(/"$/, "", service)
        } else if (modified == "" && line ~ /[0-9]{14}Z\\000/) {
            if (match(line, /[0-9]{14}Z\\000/)) {
                modified = substr(line, RSTART, RLENGTH)
                sub(/\\000$/, "", modified)
            }
        }
    }

    if (label != "" || account != "" || service != "") {
        print label "\t" account "\t" service "\t" modified
    }
}
' |
while IFS='	' read -r label account service modified; do
    [ -n "$modified" ] || continue

    modified_epoch=$(
        date -u -j -f '%Y%m%d%H%M%SZ' "$modified" +%s 2>/dev/null
    ) || continue

    expiry_epoch=$((modified_epoch + 365 * 86400))

    if [ "$expiry_epoch" -le "$CUTOFF_EPOCH" ]; then
        expiry_date=$(date -u -r "$expiry_epoch" '+%Y-%m-%d')
        printf '%s | account=%s | service=%s | modified=%s | expires=%s\n' \
            "${label:-<no label>}" \
            "${account:-<no account>}" \
            "${service:-<no service>}" \
            "${modified:-<no modified date>}" \
            "$expiry_date"
    fi
done