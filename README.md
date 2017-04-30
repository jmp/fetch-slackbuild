# Introduction

`fetchpkg` is a small utility script for Slackware. It fetches a SlackBuild and
the source tarball associated with it. It also automates some boring stuff:

* It makes sure the MD5 sum given in the SlackBuild matches the source tarball.
* It verifies the GPG signature of the SlackBuild tarball.

The script does not install or build the actual Slackware package, it simply
downloads the necessary files so that you can build and install it yourself.

# How to use

First, import the SlackBuilds.org public key to your GPG keyring:

    curl -sSL https://slackbuilds.org/GPG-KEY | gpg --import -

Then you can fetch a SlackBuild, like this:

    fetchpkg PACKAGE

This will download the SlackBuild tarball and the source tarball.
By default, all the files are downloaded to `/tmp/slackbuilds/`.

If everything goes well, you should see instructions like this:

    All done! To create your Slackware package, execute:
    
      cd /tmp/slackbuilds/PACKAGE && ./PACKAGE.SlackBuild
    

Running this command will build the Slackware package that you can then work
with the basic Slackware tools like `installpkg` or `upgradepkg`.
