#!/bin/sh -e

# Get OS release information
. /etc/*-release

SLACKBUILDS_GPG=
SLACKBUILDS_URL=https://slackbuilds.org/slackbuilds/$VERSION_ID
SLACKBUILDS_DIR=/tmp/slackbuilds
SLACKBUILDS_TXT_URL=$SLACKBUILDS_URL/SLACKBUILDS.TXT.gz
SLACKBUILDS_TXT=$SLACKBUILDS_DIR/`basename $SLACKBUILDS_TXT_URL`
INSTALLED_PACKAGES=/var/log/packages
PACKAGE=$*

if [ $# -eq 0 ]; then
  echo "No package name given."
  exit 1
fi

# Make sure we're running on Slackware
if ! [ "$NAME" = "Slackware" ]; then
  echo "Not running on Slackware; aborting."
  exit 1
fi

# Make sure the temporary directory exists
mkdir -p $SLACKBUILDS_DIR
pushd $SLACKBUILDS_DIR > /dev/null

# Download SLACKBUILDS.TXT
echo -e "Downloading list of SlackBuilds from '$SLACKBUILDS_TXT_URL'...\n"
wget -N $SLACKBUILDS_TXT_URL

if ! [ $? = 0 ]; then
  echo "Failed to download list of SlackBuilds; aborting."
  exit 1
fi

# Get package metadata
METADATA=`zcat $SLACKBUILDS_TXT | \
  grep -e "^SLACKBUILD NAME: $PACKAGE$" -A 9 -m 1`

# Make sure the package exists
if [ -z "$METADATA" ]; then
  echo "Package '$PACKAGE' not found in $SLACKBUILDS_TXT; aborting."
  exit 1
fi

# Parses the given field from the metadata
parse_field() {
  echo `echo "$METADATA" | sed -n -e "s/^SLACKBUILD $*: \(.\+\)$/\1/p"`
}

SLACKBUILD_NAME=`parse_field NAME`
SLACKBUILD_DOWNLOAD=`parse_field DOWNLOAD`
SLACKBUILD_DOWNLOAD_x86_64=`parse_field DOWNLOAD_x86_64`
SLACKBUILD_MD5SUM=`parse_field MD5SUM`
SLACKBUILD_MD5SUM_x86_64=`parse_field MD5SUM_x86_64`
SLACKBUILD_REQUIRES=`parse_field REQUIRES`

# Get the correct download link and MD5 sum based on architecture
if [ `uname -m` = "x86_64" ] && ! [ -z $SLACKBUILD_DOWNLOAD_x86_64 ]; then
  SLACKBUILD_DOWNLOAD=$SLACKBUILD_DOWNLOAD_x86_64
  SLACKBUILD_MD5SUM=$SLACKBUILD_MD5SUM_x86_64
fi

# Download the SlackBuild
SLACKBUILD_URL="$SLACKBUILDS_URL/`parse_field LOCATION`.tar.gz"
SLACKBUILD_TARBALL="$SLACKBUILDS_DIR/`basename $SLACKBUILD_URL`"
echo -e "Downloading SlackBuild from '$SLACKBUILD_URL'...\n"
wget -N $SLACKBUILD_URL
if ! [ $? = 0 ]; then
  echo "Failed to download SlackBuild; aborting."
  exit 1
fi

# If the SlackBuilds GPG key has been imported to GPG, verify the SlackBuild
gpg --list-keys $SLACKBUILDS_GPG
if [ $? = 0 ] || ! [ -z "$SLACKBUILDS_GPG_KEY" ]; then
  echo "Downloading GPG signature from '$SLACKBUILD_URL.asc'..."
  wget -N $SLACKBUILD_URL.asc
  if ! [ $? = 0 ]; then
    echo "Failed to download GPG signature; aborting."
    exit 1
  fi
  # Verify the signature
  gpg --verify $SLACKBUILD_TARBALL.asc
  if ! [ $? = 0 ]; then
    echo "Failed to verify GPG signature; aborting."
    exit 1
  fi
fi
echo -e "Not verifying GPG signature.\n"

# Extract the SlackBuild
echo -e "Extracting SlackBuild tarball '$SLACKBUILD_TARBALL'...\n"
tar xvf $SLACKBUILD_TARBALL -C $SLACKBUILDS_DIR
if ! [ $? = 0 ]; then
  echo "Failed to extract SlackBuild; aborting."
  exit 1
fi

# Download the upstream source tarball
SOURCE_TARBALL="$SLACKBUILDS_DIR/`basename $SLACKBUILD_DOWNLOAD`"
echo -e "Downloading source from '$SLACKBUILD_DOWNLOAD'...\n"
wget -N $SLACKBUILD_DOWNLOAD
if ! [ $? = 0 ]; then
  echo "Failed to download source; aborting."
  exit 1
fi

# Check the MD5 sum of the downloaded source against the one in the SlackBuild
echo "Checking MD5 sum against the one provided with SlackBuild..."
echo
md5sum $SOURCE_TARBALL
echo "$SLACKBUILD_MD5SUM  (SlackBuild)"
echo
SOURCE_MD5SUM=`md5sum $SOURCE_TARBALL | cut -f 1 -d " "`
if ! [ $SOURCE_MD5SUM = $SLACKBUILD_MD5SUM ]; then
  echo "MD5 sums do not match; aborting."
  exit 1;
else
  echo "MD5 sums match."
fi

# Print a short summary
echo
echo "All done!"
echo
echo "The SlackBuild files were extracted to '$SLACKBUILDS_DIR/$SLACKBUILD_NAME/'."
echo "Execute '`ls $SLACKBUILDS_DIR/$SLACKBUILD_NAME/*.SlackBuild`' to create your Slackware package."

# Search for dependencies and make a list of missing ones, for convenience
MISSING_DEPS=
for dep in $SLACKBUILD_REQUIRES; do
  if [ "`ls $INSTALLED_PACKAGES | grep -e '^$dep-'`" = "" ]; then
    MISSING_DEPS="$MISSING_DEPS$dep "
  fi
done
if ! [ -z "$MISSING_DEPS" ]; then
  echo "These dependencies have to be installed: $MISSING_DEPS"
fi

popd > /dev/null
