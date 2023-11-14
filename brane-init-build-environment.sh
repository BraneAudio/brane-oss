#!/bin/sh
#
# Brane Yocto Project Build Environment Setup Script
#
# Copyright 2023 Brane Audio
#
# This script is intended to setup the user's environment to build Brane OSS
# images (assuming that the Yocto layers used in the image creation have been
# setup).  Consult the README.md guide for more details which should be at the
# top level of the repo.
#

CWD=`pwd`

exit_message ()
{
   echo "If the script ran correctly, to return to this build environment later just"
   echo "rerun this script:"
   echo "      source brane-init-build-environment.sh"
}

usage()
{
   echo -e "\n Usage: source brane-init-build-environment.sh [-h]"
echo "
   Optional parameters: [-h]
   *
   * [-h]: help
   *
   * The script should be run in the same directory as the 'sources' directory.
   *
   * If creating the build directory for the first time, then the local.conf and
   * bblayers.conf files will be copied over from the brane-conf-files directory.
   *
   * If build directory has been previously setup, then it will not alter the
   * bblayers.conf or the local.conf file that are already there.
   *
"
}


clean_up()
{
   exit_message
   unset BUILD_DIR CWD DISTRO MACHINE OEROOT
   unset brane_setup_help brane_setup_error brane_cmd_line_arg
   unset usage clean_up
   unset touch_the_files
}

# The machine and distro match what is in local.conf that will be copied over.
MACHINE="brane-machine"
DISTRO='brane-oss-dist'
BUILD_DIR="${MACHINE}-build"

# get command line options
OPTIND=1
while getopts "h" brane_cmd_line_arg
do
   case $brane_cmd_line_arg in
      h) brane_setup_help='true';
         ;;
      \?) brane_setup_error='true';
         ;;
   esac
done
shift $((OPTIND-1))
if [ $# -ne 0 ]; then
   brane_setup_error=true
   echo -e "Invalid command line ending: '$@'"
fi
if test $brane_setup_help; then
   usage && clean_up && return 1
elif test $brane_setup_error; then
   clean_up && return 1
fi

echo "Setting up for Brane image build"
echo "Setting up to build $MACHINE Images."
echo "Setting build directory to $BUILD_DIR"

OEROOT=$PWD/sources/poky
if [ -e $PWD/sources/oe-core ]; then
   OEROOT=$PWD/sources/oe-core
fi

# Set up the basic yocto environment (this will move into build directory)
. $OEROOT/oe-init-build-env $CWD/$BUILD_DIR > /dev/null

# If the above script ran correctly, then will be in the build directory now.

if [ ! -e conf/local.conf ]; then
    echo -e "ERROR: Build directory file not created!!"
   clean_up && return 1
fi

export PATH="`echo $PATH | sed 's/\(:.\|:\)*:/:/g;s/^.\?://;s/:.\?$//'`"

if [ ! -e conf/brane.image.touched ]; then
   # This will alllow the first time using the script to overwrite the
   # local.conf and bblayers.conf files.  A single backup file for each will be
   # kept that will have a .brane-bak extension.
   rm -f conf/*.touched
   touch conf/brane.image.touched
   touch_the_files="true"
fi

if [ "$touch_the_files" = "true" ]; then
   echo "Touching the local.conf and bblayers.conf."

   cp ../brane-conf-files/local.conf conf/local.conf
   cp ../brane-conf-files/bblayers.conf conf/bblayers.conf
fi

cat <<EOF

Brane Image initial setup.

The Yocto Project has extensive documentation about OE including a
reference manual which can be found at:
    http://yoctoproject.org/documentation

For more information about OpenEmbedded see their website:
    http://www.openembedded.org/

You can now run 'bitbake <target>'

The Brane target is:
   brane-oss-image

EOF

# All changes to local.conf and bblayers.conf should be done once we get here.
if [ "$touch_the_files" = "true" ]; then
   # Make backups so one can get back to original easily if they
   # change things.
   cp conf/local.conf conf/local.conf.brane-bak
   cp conf/bblayers.conf conf/bblayers.conf.brane-bak

    cat <<EOF
Your build environment has been configured with:

    MACHINE=$MACHINE
    DISTRO=$DISTRO
EOF
else
    echo "Your configuration files at $BUILD_DIR have not been touched."
fi

clean_up
