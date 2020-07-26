#!/bin/sh

# Get OS release information
. /etc/*-release

# This is the directory where all the downloaded files will be downloaded
DOWNLOADS_DIR=/tmp/slackbuilds

# The base URL where the SlackBuild files will be downloaded from
SLACKBUILDS_URL=https://slackbuilds.org/slackbuilds/$VERSION_ID

# This is the package name given as an argument
PACKAGE=$*

# Make sure we're running on Slackware
if ! [ "$NAME" = "Slackware" ]; then
  echo "Not running on Slackware; aborting."
  exit 1
fi

# Show help if no arguments are given
if [ $# -eq 0 ]; then
  echo "usage: $0 PACKAGE"
  exit 1
fi

# Make sure the downloads directory exists
install -g users -m 0770 -d $DOWNLOADS_DIR

# Download SLACKBUILDS.TXT
SLACKBUILDS_TXT_URL=$SLACKBUILDS_URL/SLACKBUILDS.TXT.gz
SLACKBUILDS_TXT=$DOWNLOADS_DIR/$(basename "$SLACKBUILDS_TXT_URL")
echo "Updating SlackBuild list from $SLACKBUILDS_TXT_URL..."

if ! wget -qNP $DOWNLOADS_DIR "$SLACKBUILDS_TXT_URL"; then
  echo "Failed to download list of SlackBuilds; aborting."
  exit 1
fi

# Get package metadata
METADATA=$(zgrep -e "^SLACKBUILD NAME: $PACKAGE$" -A 9 -m 1 "$SLACKBUILDS_TXT")

# Make sure the package exists
if [ -z "$METADATA" ]; then
  echo "Package '$PACKAGE' not found; aborting."
  exit 1
fi

# Reads the given field from the metadata
read_metadata_field() {
  echo "$(echo "$METADATA" | sed -n -e "s/^SLACKBUILD $*: \(.\+\)$/\1/p")"
}

SLACKBUILD_NAME=$(read_metadata_field NAME)
SLACKBUILD_DOWNLOAD_x86_64=$(read_metadata_field DOWNLOAD_x86_64)

# Get the correct download link and MD5 sum based on architecture
if [ "$(uname -m)" = "x86_64" ] && [ -n "$SLACKBUILD_DOWNLOAD_x86_64" ]; then
  SLACKBUILD_DOWNLOAD=$SLACKBUILD_DOWNLOAD_x86_64
  SLACKBUILD_MD5SUM=$(read_metadata_field MD5SUM_x86_64)
else
  SLACKBUILD_DOWNLOAD=$(read_metadata_field DOWNLOAD)
  SLACKBUILD_MD5SUM=$(read_metadata_field MD5SUM)
fi

# Make sure there is a download URL
if [ "$SLACKBUILD_DOWNLOAD" = "UNSUPPORTED" ]; then
  echo "This package is not supported on your architecture."
  exit 1
fi

# Download the SlackBuild
SLACKBUILD_URL=$SLACKBUILDS_URL/$(echo $(read_metadata_field LOCATION) | cut -c 3-).tar.gz
SLACKBUILD_TARBALL=$DOWNLOADS_DIR/$(basename "$SLACKBUILD_URL")
echo "Downloading SlackBuild from $SLACKBUILD_URL..."
if ! wget -qNP "$DOWNLOADS_DIR" "$SLACKBUILD_URL"; then
  echo "Failed to download SlackBuild; aborting."
  exit 1
fi

# Extract the SlackBuild
echo "Extracting SlackBuild tarball $SLACKBUILD_TARBALL..."
if ! tar -xf "$SLACKBUILD_TARBALL" -C $DOWNLOADS_DIR; then
  echo "Failed to extract SlackBuild tarball; aborting."
  exit 1
fi

# Download the upstream source tarball
SOURCE_TARBALL=$DOWNLOADS_DIR/$SLACKBUILD_NAME/$(basename "$SLACKBUILD_DOWNLOAD")
echo "Downloading source archive from $SLACKBUILD_DOWNLOAD..."
if ! wget -qNP "$(dirname "$SOURCE_TARBALL")" "$SLACKBUILD_DOWNLOAD"; then
  echo "Failed to download source archive; aborting."
  exit 1
fi

# Check the MD5 sum of the downloaded source against the one in the SlackBuild
echo "Checking MD5 sum against the one provided with SlackBuild..."
if ! echo "$SLACKBUILD_MD5SUM $SOURCE_TARBALL" | md5sum --quiet -c; then
  echo "MD5 sums do not match; aborting."
  exit 1
fi

# Print a short summary
echo "All done! To create your Slackware package, execute (as root):"
echo
echo "  cd $DOWNLOADS_DIR/$SLACKBUILD_NAME && ./$SLACKBUILD_NAME.SlackBuild"
echo

# Search for dependencies and make a list of missing ones, for convenience
PACKAGES_DIR=/var/log/packages
SLACKBUILD_REQUIRES=$(read_metadata_field REQUIRES)
MISSING_DEPS=
if [ -n "$SLACKBUILD_REQUIRES" ]; then
  INSTALLED_PACKAGES=$(ls $PACKAGES_DIR)
  for dep in $SLACKBUILD_REQUIRES; do
    if [ "$(echo "$INSTALLED_PACKAGES" | grep -e "^$dep-")" = "" ]; then
      MISSING_DEPS="$MISSING_DEPS $dep"
    fi
  done
fi

if [ -n "$MISSING_DEPS" ]; then
  echo "These dependencies have to be installed:$MISSING_DEPS"
fi
