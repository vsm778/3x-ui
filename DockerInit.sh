#!/bin/sh
set -e

# Optional directory with pre-downloaded files used as fallback when GitHub is unavailable.
DOWNLOAD_FALLBACK_DIR="${DOWNLOAD_FALLBACK_DIR:-}"

log_info() {
    echo "[INFO] $*"
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

download_or_fallback() {
    url="$1"
    file_name="$2"

    log_info "Starting download: $file_name"

    if curl --connect-timeout 10 --max-time 300 -sfLRO "$url"; then
        log_info "Download completed: $file_name"
        return 0
    else
        curl_exit_code=$?
    fi

    if [ "$curl_exit_code" -eq 28 ]; then
        log_warn "Download timed out: $file_name"
    else
        log_warn "Download failed: $file_name (curl exit code: $curl_exit_code)"
    fi

    if [ -n "$DOWNLOAD_FALLBACK_DIR" ] && [ -f "$DOWNLOAD_FALLBACK_DIR/$file_name" ]; then
        log_info "Using fallback file: $DOWNLOAD_FALLBACK_DIR/$file_name"
        cp "$DOWNLOAD_FALLBACK_DIR/$file_name" "$file_name"
        log_info "Fallback copy completed: $file_name"
        return 0
    fi

    log_error "Failed to download $file_name and fallback file was not found"
    return 1
}

case $1 in
    amd64)
        ARCH="64"
        FNAME="amd64"
        ;;
    i386)
        ARCH="32"
        FNAME="i386"
        ;;
    armv8 | arm64 | aarch64)
        ARCH="arm64-v8a"
        FNAME="arm64"
        ;;
    armv7 | arm | arm32)
        ARCH="arm32-v7a"
        FNAME="arm32"
        ;;
    armv6)
        ARCH="arm32-v6"
        FNAME="armv6"
        ;;
    *)
        ARCH="64"
        FNAME="amd64"
        ;;
esac
mkdir -p build/bin
cd build/bin
download_or_fallback "https://github.com/XTLS/Xray-core/releases/download/v26.4.25/Xray-linux-${ARCH}.zip" "Xray-linux-${ARCH}.zip"
log_info "Extracting archive: Xray-linux-${ARCH}.zip"
unzip "Xray-linux-${ARCH}.zip"
rm -f "Xray-linux-${ARCH}.zip"
mv xray "xray-linux-${FNAME}"
chmod +x "xray-linux-${FNAME}"
log_info "Prepared Xray binary: xray-linux-${FNAME}"
download_or_fallback https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat geoip.dat
download_or_fallback https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat geosite.dat
download_or_fallback https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat geoip_IR.dat
download_or_fallback https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat geosite_IR.dat
download_or_fallback https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat geoip_RU.dat
download_or_fallback https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat geosite_RU.dat
cd ../../
