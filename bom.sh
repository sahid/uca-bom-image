#!/bin/bash

set -xe

export LANG="en_US.UTF-8"

# Should be set from ENV
#TARGET="trusty-mitaka"
#OS_SERIES="folsom"
#TESTING_PPA="ppa:openstack-ubuntu-testing/folsom-stable-testing"
# end

staging_ppa="ppa:ubuntu-cloud-archive/$OS_SERIES-staging"
packages=($(cloud-archive-outdated-packages -P $OS_SERIES))

for pkg in ${packages[*]}; do
    cloud-archive-backport -P -r $OS_SERIES -o . $pkg || {
        echo "Autobackport failed, patch may need a refresh"
    }
    DEB_BUILD_OPTIONS=nostrip sbuild-$OS_SERIES -n -A ${pkg}*/*.dsc && {
        debsign -k9935ACDC ${pkg}*/*_source.changes
        dput -f $staging_ppa ${pkg}*/*_source.changes
        dput -f $TESTING_PPA ${pkg}*/*_source.changes
        reprepro --waitforlock 10 -b ${HOME}/www/apt includedeb $TARGET *.deb
        rm -f *.deb *.changes
    } || {
        echo "Failed to build $pkg - retry later" >> failed.txt
    }
done

if [ -f failed.txt ]; then
    cat failed.txt
    exit 1
fi
