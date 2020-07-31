# Introduction

`fetch-slackbuild.sh` is a small utility script for Slackware. It fetches a
SlackBuild and the source tarball associated with it. It also automates some
boring stuff like verifying the MD5 sum of the tarball.

Basically, this is what it does:

* It downloads the given SlackBuild from https://slackbuilds.org/.
* It downloads the source tarball from the original source.
* It makes sure the MD5 sum given in the SlackBuild matches the source tarball.
* It shows a list of dependencies that must be installed for the package.

The script does *not* install or build the actual Slackware package, it simply
downloads the necessary files so that you can build and install it yourself
using the usual Slackware tools. After downloading the necessary files, you are
free to build and install the package any way you wish.

This is just a small utility script that works for my own (very basic) needs.
For a much better and more advanced tool, you probably want something like
`sbopkg` (https://sbopkg.org) instead.

# How to use

Run the script with a package name as an argument. For example, to fetch `ack`:

    ./fetch-slackbuild.sh ack

This will download the SlackBuild tarball from https://slackbuilds.org/, and the
source archive from the URL defined in the SlackBuild's metadata. The output should
look something like this:

    Updating SlackBuild list from https://slackbuilds.org/slackbuilds/14.2/SLACKBUILDS.TXT.gz...
    Downloading SlackBuild from https://slackbuilds.org/slackbuilds/14.2/system/ack.tar.gz...
    Extracting SlackBuild tarball /tmp/slackbuilds/ack.tar.gz...
    Downloading source archive from https://beyondgrep.com/ack-v3.3.1...
    Checking MD5 sum against the one provided with SlackBuild...
    All done! To create your Slackware package, execute (as root):

      cd /tmp/slackbuilds/ack && ./ack.SlackBuild

Running this command will build the Slackware package that you can then work
with the basic Slackware tools like `installpkg` or `upgradepkg`. For example,
to install the generated `ack` Slackware package (as `root`):

    installpkg /tmp/ack-3.3.1-noarch-1_SBo.tgz
