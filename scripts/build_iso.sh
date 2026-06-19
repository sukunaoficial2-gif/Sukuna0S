#!/bin/bash
# SukunaOS ISO Build Script

set -e
set -o pipefail

echo "🔴 Starting SukunaOS ISO build..."
echo "Build directory: $(pwd)"
echo ""

# Create temporary build directory
BUILD_DIR="/tmp/sukunaos-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/work"
cd "$BUILD_DIR/work"

echo "✅ Build directory ready at: $BUILD_DIR"
echo ""

# Initialize live-build configuration
echo "🔴 Initializing live-build configuration..."
lb config \
  --architecture amd64 \
  --mode debian \
  --distribution bookworm \
  --archive-areas "main contrib non-free non-free-firmware" \
  --apt-recommends true \
  --bootloaders grub-efi,syslinux \
  --debian-installer live \
  --debian-installer-distribution bookworm \
  --debootstrap-options "--keyring=/usr/share/keyrings/debian-archive-keyring.gpg" \
  --firmware-chroot true \
  --image-type iso-hybrid \
  --initramfs live-boot \
  --linux-packages linux-image \
  --memtest86+ true \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian \
  --mirror-chroot-security http://security.debian.org/debian-security \
  --mirror-binary http://deb.debian.org/debian \
  --mirror-binary-security http://security.debian.org/debian-security \
  --security true

echo "✅ Live-build configured"
echo ""

# Create package list
echo "🔴 Creating package list..."
mkdir -p config/package-lists
cat > config/package-lists/standard.list.chroot << 'EOF'
# Standard system packages
sudo
curl
wget
git
nano
vim
htop
net-tools
openssh-client
openssh-server
build-essential
grub-pc
grub-efi-amd64
linux-image-amd64
EOF

echo "✅ Package list created"
echo ""

# Build the ISO
echo "🔴 Building ISO image..."
echo "This may take 10-25 minutes..."
echo ""

lb build 2>&1 | tee build.log

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ ISO build completed successfully!"
  
  # Find and display ISO file
  if [ -f "live-image-amd64.iso" ]; then
    ISO_SIZE=$(ls -lh live-image-amd64.iso | awk '{print $5}')
    echo "📦 ISO created: live-image-amd64.iso ($ISO_SIZE)"
    
    # Copy to workspace
    if [ -n "$GITHUB_WORKSPACE" ]; then
      cp live-image-amd64.iso "$GITHUB_WORKSPACE/live-build/" 2>/dev/null || true
      echo "📁 ISO copied to workspace"
    fi
  fi
else
  echo ""
  echo "❌ ISO build failed!"
  echo "Check build.log for details"
  exit 1
fi

echo ""
echo "✅ Build script completed successfully!"
