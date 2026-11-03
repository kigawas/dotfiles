#!/usr/bin/env bash
# Setup script for the Mobile cloud environment.
#
# Installs the Android SDK (command-line tools, platform-tools, platform 37.0,
# build-tools 36.0.0) into /opt/android-sdk and the Kotlin compiler into
# /opt/kotlinc, and links the dotfiles. Every step checks what is already in
# place, so running it again is safe.
set -euo pipefail

CMDLINE_TOOLS_BUILD=16111833 # cmdline-tools 23.0
CMDLINE_TOOLS_SHA256=0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8
ANDROID_PACKAGES=(platform-tools platforms/android-37.0 build-tools/36.0.0)
KOTLIN_VERSION=2.4.21
KOTLIN_SHA256=7cc140e76daf416a0424a5557f99afd7ca89ebd463ea1101261e3e01c33e75cd
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36'

export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk

rm -rf /tmp/mobile-setup
mkdir -p /tmp/mobile-setup
trap 'rm -rf /tmp/mobile-setup' EXIT

# Download a file and check its SHA-256: download <url> <sha256> <dest>
download() {
  curl -fsSL --retry 3 -A "$UA" -o "$3" "$1"
  echo "$2  $3" | sha256sum -c -
}

# Dotfiles
if [ ! -d /home/user/dotfiles/.git ]; then
  git clone --depth 1 https://github.com/kigawas/dotfiles /home/user/dotfiles
fi
/home/user/dotfiles/install.sh --apply

# Android command-line tools
if ! grep -qs '^Pkg.Revision=23.0$' /opt/android-sdk/cmdline-tools/latest/source.properties; then
  download "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_BUILD}_latest.zip" \
    "$CMDLINE_TOOLS_SHA256" /tmp/mobile-setup/clt.zip
  unzip -q /tmp/mobile-setup/clt.zip -d /tmp/mobile-setup
  rm -rf /opt/android-sdk/cmdline-tools/latest
  mkdir -p /opt/android-sdk/cmdline-tools
  mv /tmp/mobile-setup/cmdline-tools /opt/android-sdk/cmdline-tools/latest
fi

# SDK packages. sdkmanager is now a wrapper around the android CLI, which
# accepts the SDK licenses as part of the install and skips packages that are
# already installed.
/opt/android-sdk/cmdline-tools/latest/bin/android sdk install "${ANDROID_PACKAGES[@]}"

# Kotlin compiler
if ! grep -qsxF "$KOTLIN_VERSION" /opt/kotlinc/build.txt; then
  download "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
    "$KOTLIN_SHA256" /tmp/mobile-setup/kotlin.zip
  unzip -q /tmp/mobile-setup/kotlin.zip -d /tmp/mobile-setup
  rm -rf /opt/kotlinc
  mv /tmp/mobile-setup/kotlinc /opt/kotlinc
fi

# Environment for login shells
cat > /etc/profile.d/android.sh <<'EOF'
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
case ":$PATH:" in
  *:/opt/android-sdk/platform-tools:*) ;;
  *) export PATH="/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/kotlinc/bin:$PATH" ;;
esac
EOF

# Commands in /usr/local/bin, so shells that skip /etc/profile.d find them too.
# These are small wrappers, not symlinks: sdkmanager finds the SDK from its own
# directory, and the android CLI falls back to ~/Android/Sdk when ANDROID_HOME
# is unset.
for tool in \
  cmdline-tools/latest/bin/android \
  cmdline-tools/latest/bin/sdkmanager \
  cmdline-tools/latest/bin/avdmanager \
  platform-tools/adb; do
  cat > "/usr/local/bin/${tool##*/}" <<EOF
#!/bin/sh
: "\${ANDROID_HOME:=/opt/android-sdk}"
export ANDROID_HOME
exec /opt/android-sdk/$tool "\$@"
EOF
  chmod 755 "/usr/local/bin/${tool##*/}"
done
for tool in kotlinc kotlin; do
  ln -sfn "/opt/kotlinc/bin/$tool" "/usr/local/bin/$tool"
done

# local.properties for each Gradle project checked out under /home/user. A
# session without a repository has none, so this step does nothing there.
for settings in /home/user/*/settings.gradle /home/user/*/settings.gradle.kts; do
  if [ -f "$settings" ]; then
    echo "sdk.dir=/opt/android-sdk" > "${settings%/*}/local.properties"
  fi
done

adb version
kotlinc -version
