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

You can fetch a SlackBuild like this:

    ./fetch-slackbuild.sh PACKAGE

This will download the SlackBuild tarball and the source tarball.
By default, all the files are downloaded to `/tmp/slackbuilds/`.

If everything goes well, you should see instructions like this:

    All done! To create your Slackware package, execute:
    
      cd /tmp/slackbuilds/PACKAGE && ./PACKAGE.SlackBuild
    

Running this command will build the Slackware package that you can then work
with the basic Slackware tools like `installpkg` or `upgradepkg`.
