#!/data/data/com.termux/files/usr/bin/bash

# Title: Nmap Module Builder v2.1.0
# Target: Termux (Android)
# Description: Compiles Nmap with OpenSSL and Libpcap support.

set -e

# --- Configuration ---
VERSION="7.94" # Current stable; adjust if specifically targeting a legacy v2.1.0
PREFIX_DIR=$PREFIX
BUILD_DIR="$HOME/nmap_build_v2.1.0"
JOBS=$(nproc)

echo "[*] Initializing Termux Build Environment..."

# 1. Setup Storage & Dependencies
termux-setup-storage
pkg update -y
pkg install -y \
    binutils \
    build-essential \
    clang \
    make \
    pkg-config \
    openssl \
    libpcap \
    libpcre2 \
    liblua54 \
    zlib \
    curl

# 2. Prepare Build Directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 3. Fetch Source
if [ ! -f "nmap-$VERSION.tar.bz2" ]; then
    echo "[*] Downloading Nmap v$VERSION..."
    curl -O "https://nmap.org/dist/nmap-$VERSION.tar.bz2"
fi

tar -xjf "nmap-$VERSION.tar.bz2"
cd "nmap-$VERSION"

# 4. Configure Build
# We use --with-libpcap=$PREFIX to ensure it links against Termux's patched pcap
# --without-zenmap is mandatory as GTK/Python GUI is not supported natively in shell
echo "[*] Configuring source for Termux prefix..."
./configure \
    --prefix="$PREFIX_DIR" \
    --with-openssl="$PREFIX_DIR" \
    --with-libpcap="$PREFIX_DIR" \
    --with-libpcre="$PREFIX_DIR" \
    --with-libz="$PREFIX_DIR" \
    --with-liblua="$PREFIX_DIR" \
    --without-zenmap \
    --without-ndiff \
    --without-nmap-update

# 5. Compile
echo "[*] Compiling with $JOBS cores..."
make -j"$JOBS"

# 6. Installation & Strip
echo "[*] Installing binaries..."
make install

# Strip symbols to reduce binary size (optimization for mobile)
echo "[*] Optimizing binaries..."
strip "$PREFIX_DIR/bin/nmap"
strip "$PREFIX_DIR/bin/nping"

echo "[+] Build v2.1.0 Complete. Verify with: nmap --version"