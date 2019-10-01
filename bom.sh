#!/bin/bash

set -xe

export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export LC_ALL="C"


: ${GPG_PUBLIC_KEYS_IMPORT:="/secrets/pgp-public-keys"}
: ${GPG_PRIVATE_KEYS_IMPORT:="/secrets/pgp-public-keys"}
: ${DEBSIGN_KEY:="9935ACDC"}

: ${BLACKLIST:=""}

: ${BASE_STAGING_PPA:="ppa:ubuntu-cloud-archive"}

if [ -z "$TARGET" ]; then
  echo "ERROR: TARGET should be defined, e.g. trusty-mitaka."
  exit 1
fi
if [ -z "$OS_SERIES" ]; then
  echo "ERROR: OS_SERIES should be defined, e.g. mitaka."
  exit 1
fi
if [ -z "$TESTING_PPA" ]; then
  echo "ERROR: TESTING_PPA should be defined, e.g. ppa:openstack-ubuntu-testing/mitaka."
  exit 1
fi


if [ $ONLY_BUILD ]
then
    echo "Running is dry-mode, only builds will be executed."
fi


function blacklisted {
    pkg=$1
    for bl_pkg in ${BLACKLIST[*]}; do
        if [ $pkg == $bl_pkg ]; then
        	return 0
        fi    	
    done
    return 1
}


# Configure the keys.
gpg --import $GPG_PUBLIC_KEYS_IMPORT
gpg --import $GPG_PRIVATE_KEYS_IMPORT
gpg --list-keys


staging_ppa="$BASE_STAGING_PPA/$OS_SERIES-staging"
packages=($(cloud-archive-outdated-packages -P $OS_SERIES))

for pkg in ${packages[*]}; do
    if blacklisted $pkg; then
    	echo "Package $pkg blacklisted, skipping"
    	continue
    fi
    cloud-archive-backport -P -r $OS_SERIES -o . $pkg || {
        echo "Autobackport failed, patch may need a refresh"
    }
    DEB_BUILD_OPTIONS=nostrip sbuild-$OS_SERIES -n -A ${pkg}*/*.dsc && {
        debsign -k$DEBSIGN_KEY ${pkg}*/*_source.changes
	if [ -n $ONLY_BUILD ]
	then
            dput -f $staging_ppa ${pkg}*/*_source.changes
            dput -f $TESTING_PPA ${pkg}*/*_source.changes
            reprepro --waitforlock 10 -b ${HOME}/www/apt includedeb $TARGET *.deb
	fi
    } || {
        echo "Failed to build $pkg - retry later" >> failed.txt
    }
done

if [ -f failed.txt ]; then
    cat failed.txt
    exit 1
fi
