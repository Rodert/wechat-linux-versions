#!/usr/bin/env bash

set -euo pipefail

readonly DOWNLOAD_PAGE_URL='https://linux.weixin.qq.com/'
readonly WORK_DIR="$(mktemp -d)"
declare -a PACKAGE_URLS=()
declare -a ASSETS=()

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

require_commands() {
    command -v curl >/dev/null
    command -v dpkg-deb >/dev/null
    command -v gh >/dev/null
    command -v sha256sum >/dev/null
}

discover_packages() {
    mapfile -t PACKAGE_URLS < <(
        curl --fail --location --silent --show-error "$DOWNLOAD_PAGE_URL" \
            | grep -Eo 'https?://[^" ]+/[^" ]*WeChatLinux[^" ]*\.(deb|rpm|AppImage)(\?[^" ]*)?' \
            | sed 's/&amp;/\&/g' \
            | sort -u
    )

    if [ "${#PACKAGE_URLS[@]}" -eq 0 ]; then
        echo 'No WeChat Linux packages were found on the official download page.' >&2
        exit 1
    fi
}

download_packages() {
    local url filename
    for url in "${PACKAGE_URLS[@]}"; do
        filename="${url%%\?*}"
        filename="${filename##*/}"
        echo "Downloading $filename"
        curl --fail --location --retry 3 --output "$WORK_DIR/$filename" "$url"
    done
}

read_version() {
    local deb_file
    deb_file="$(find "$WORK_DIR" -maxdepth 1 -type f -name '*.deb' | head -n 1)"
    if [ -z "$deb_file" ]; then
        echo 'Unable to find a Debian package to read the WeChat version.' >&2
        exit 1
    fi

    VERSION="$(dpkg-deb -f "$deb_file" Version | sed 's/-[^-]*$//')"
    if [ -z "$VERSION" ]; then
        echo 'Unable to determine the WeChat version.' >&2
        exit 1
    fi
}

package_signature() {
    local url filename
    for url in "${PACKAGE_URLS[@]}"; do
        filename="${url%%\?*}"
        filename="${filename##*/}"
        printf '%s  %s\n' "$filename" "$(sha256sum "$WORK_DIR/$filename" | awk '{print $1}')"
    done | sort | sha256sum | awk '{print $1}'
}

create_release() {
    local filename checksum notes latest_signature tag url
    notes="$WORK_DIR/WeChatLinux-$VERSION.sha256"
    : > "$notes"
    printf 'DestVersion: %s\nPackageSignature: %s\nUpdateTime: %s (UTC)\n\n' \
        "$VERSION" "$SIGNATURE" "$(date -u '+%Y-%m-%d %H:%M:%S')" >> "$notes"

    for url in "${PACKAGE_URLS[@]}"; do
        filename="${url%%\?*}"
        filename="$WORK_DIR/${filename##*/}"
        checksum="$(sha256sum "$filename" | awk '{print $1}')"
        printf 'File: %s\nSha256: %s\nDownloadFrom: %s\n\n' \
            "$(basename "$filename")" "$checksum" \
            "$url" >> "$notes"
        ASSETS+=("$filename")
    done
    ASSETS+=("$notes")

    latest_signature="$(gh release view --json body --jq '.body' 2>/dev/null | awk -F': ' '/^PackageSignature:/ {print $2; exit}' || true)"
    if [ -n "$latest_signature" ] && [ "$SIGNATURE" = "$latest_signature" ]; then
        echo 'The latest official package set is already archived.'
        return
    fi

    tag="v$VERSION"
    if gh release view "$tag" >/dev/null 2>&1; then
        tag="$tag-$(date -u '+%Y%m%d')"
    fi
    gh release create "$tag" "${ASSETS[@]}" --title "WeChat Linux v${tag#v}" --notes-file "$notes"
}

main() {
    require_commands
    discover_packages
    download_packages
    read_version
    SIGNATURE="$(package_signature)"
    echo "WeChat Linux version: $VERSION"
    create_release
}

main "$@"
