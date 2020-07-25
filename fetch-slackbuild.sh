#!/bin/sh

# Get OS release information
. /etc/*-release

SLACKBUILDS_URL=https://slackbuilds.org/slackbuilds/$VERSION_ID
SLACKBUILDS_DIR=/tmp/slackbuilds
SLACKBUILDS_TXT_URL=$SLACKBUILDS_URL/SLACKBUILDS.TXT.gz
SLACKBUILDS_TXT=$SLACKBUILDS_DIR/$(basename $SLACKBUILDS_TXT_URL)
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

# Make sure the temporary directory exists
mkdir -p $SLACKBUILDS_DIR
pushd $SLACKBUILDS_DIR > /dev/null

# Download SLACKBUILDS.TXT
echo -e "Updating SlackBuild list from $SLACKBUILDS_TXT_URL..."
wget -qN $SLACKBUILDS_TXT_URL

if ! [ $? = 0 ]; then
  echo "Failed to download list of SlackBuilds; aborting."
  exit 1
fi

# Get package metadata
METADATA=$(zcat $SLACKBUILDS_TXT | \
  grep -e "^SLACKBUILD NAME: $PACKAGE$" -A 9 -m 1)

# Make sure the package exists
if [ -z "$METADATA" ]; then
  echo "Package '$PACKAGE' not found in $SLACKBUILDS_TXT; aborting."
  exit 1
fi

# Reads the given field from the metadata
read_metadata_field() {
  echo $(echo "$METADATA" | sed -n -e "s/^SLACKBUILD $*: \(.\+\)$/\1/p")
}

SLACKBUILD_NAME=$(read_metadata_field NAME)
SLACKBUILD_REQUIRES=$(read_metadata_field REQUIRES)
SLACKBUILD_DOWNLOAD_x86_64=$(read_metadata_field DOWNLOAD_x86_64)

# Get the correct download link and MD5 sum based on architecture
if [ $(uname -m) = "x86_64" ] && ! [ -z $SLACKBUILD_DOWNLOAD_x86_64 ]; then
  SLACKBUILD_DOWNLOAD=$SLACKBUILD_DOWNLOAD_x86_64
  SLACKBUILD_MD5SUM=$(read_metadata_field MD5SUM_x86_64)
else
  SLACKBUILD_DOWNLOAD=$(read_metadata_field DOWNLOAD)
  SLACKBUILD_MD5SUM=$(read_metadata_field MD5SUM)
fi

# Make sure there is a download URL
if [ $SLACKBUILD_DOWNLOAD = "UNSUPPORTED" ]; then
  echo "This package is not supported on your architecture."
  exit 1
fi

# Download the SlackBuild
SLACKBUILD_URL="$SLACKBUILDS_URL/$(read_metadata_field LOCATION).tar.gz"
SLACKBUILD_TARBALL="$SLACKBUILDS_DIR/$(basename $SLACKBUILD_URL)"
echo -e "Downloading SlackBuild from $SLACKBUILD_URL..."
wget -qN $SLACKBUILD_URL
if ! [ $? = 0 ]; then
  echo "Failed to download SlackBuild; aborting."
  exit 1
fi

# Extract the SlackBuild
echo -e "Extracting SlackBuild tarball $SLACKBUILD_TARBALL..."
tar -xf $SLACKBUILD_TARBALL -C $SLACKBUILDS_DIR
if ! [ $? = 0 ]; then
  echo "Failed to extract SlackBuild tarball; aborting."
  exit 1
fi

# Download the upstream source tarball
SOURCE_TARBALL="$SLACKBUILDS_DIR/$SLACKBUILD_NAME/$(basename $SLACKBUILD_DOWNLOAD)"
pushd $(dirname $SOURCE_TARBALL) > /dev/null
echo -e "Downloading source archive from $SLACKBUILD_DOWNLOAD..."
wget -qN $SLACKBUILD_DOWNLOAD
if ! [ $? = 0 ]; then
  echo "Failed to download source archive; aborting."
  exit 1
fi
popd > /dev/null

# Check the MD5 sum of the downloaded source against the one in the SlackBuild
echo "Checking MD5 sum against the one provided with SlackBuild..."
md5sum --quiet -c <<< "$SLACKBUILD_MD5SUM $SOURCE_TARBALL"
if ! [ $? = 0 ]; then
  echo "MD5 sums do not match; aborting."
  exit 1
fi

# Print a short summary
echo "All done! To create your Slackware package, execute:"
echo
echo "  cd $SLACKBUILDS_DIR/$SLACKBUILD_NAME && ./$SLACKBUILD_NAME.SlackBuild"
echo

# Search for dependencies and make a list of missing ones, for convenience
MISSING_DEPS=
for dep in $SLACKBUILD_REQUIRES; do
  if [ "$(ls /var/log/packages | grep -e '^$dep-')" = "" ]; then
    MISSING_DEPS="$MISSING_DEPS$dep "
  fi
done
if ! [ -z "$MISSING_DEPS" ]; then
  echo "These dependencies have to be installed: $MISSING_DEPS"
fi

popd > /dev/null

