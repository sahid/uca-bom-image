#!/bin/bash

set -xe

export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export LC_ALL="C"

# Should be set from ENV
#TARGET="trusty-mitaka"
#OS_SERIES="folsom"
#TESTING_PPA="ppa:openstack-ubuntu-testing/folsom-stable-testing"
#ONLY_BUILD=1 t run is dry mode.export 
# end

staging_ppa="ppa:ubuntu-cloud-archive/$OS_SERIES-staging"
packages=($(cloud-archive-outdated-packages -P $OS_SERIES))

for pkg in ${packages[*]}; do
    cloud-archive-backport -P -r $OS_SERIES -o . $pkg || {
        echo "Autobackport failed, patch may need a refresh"
    }
    DEB_BUILD_OPTIONS=nostrip sbuild-$OS_SERIES -n -A ${pkg}*/*.dsc && {
        debsign -k9935ACDC ${pkg}*/*_source.changes
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
