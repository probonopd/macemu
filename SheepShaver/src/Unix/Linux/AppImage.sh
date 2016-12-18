#!/bin/bash

########################################################################
# Package the binaries built on Travis-CI as an AppImage
# By Simon Peter 2016
# For more information, see http://appimage.org/
########################################################################

export ARCH=$(arch)

APP=SheepShaver
LOWERAPP=${APP,,}

mkdir -p $HOME/$APP/$APP.AppDir/usr/

cd $HOME/$APP/

wget -q https://github.com/probonopd/AppImages/raw/master/functions.sh -O ./functions.sh
. ./functions.sh

cd $APP.AppDir

sudo chown -R $USER /shp/

# SheepShaver had been installed to the PREFIX /shp before
cp -r /shp/* ./usr/

########################################################################
# Copy desktop and icon file to AppDir for AppRun to pick them up
########################################################################

get_apprun
wget -c "https://raw.githubusercontent.com/rpmfusion/SheepShaver/master/SheepShaver.desktop"
sed -i -e 's|Sheep Shaver|SheepShaver|g' SheepShaver.desktop
wget -c "https://github.com/rpmfusion/SheepShaver/raw/master/SheepShaver.png"

########################################################################
# Other appliaction-specific finishing touches
########################################################################

# Get AppStream metadata
mkdir -p usr/share/appdata/
( cd usr/share/appdata/ ; wget -c "https://raw.githubusercontent.com/rpmfusion/SheepShaver/master/SheepShaver.appdata.xml" )

########################################################################
# Copy in the dependencies that cannot be assumed to be available
# on all target systems
########################################################################

copy_deps

########################################################################
# Delete stuff that should not go into the AppImage
########################################################################

# Delete dangerous libraries; see
# https://github.com/probonopd/AppImages/blob/master/excludelist
delete_blacklisted

########################################################################
# desktopintegration asks the user on first run to install a menu item
########################################################################

get_desktopintegration $APP

########################################################################
# Determine the version of the app; also include needed glibc version
########################################################################

VER1=$(printf "%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)")
GLIBC_NEEDED=$(glibc_needed)
VERSION=$VER1-glibc$GLIBC_NEEDED

########################################################################
# Patch away absolute paths; it would be nice if they were relative
########################################################################

find usr/ -type f -exec sed -i -e 's|/usr|././|g' {} \;
find usr/ -type f -exec sed -i -e 's|/shp|././|g' {} \;
find usr/ -type f -exec sed -i -e 's@././/bin/env@/usr/bin/env@g' {} \;

########################################################################
# AppDir complete
# Now packaging it as an AppImage
########################################################################

cd .. # Go out of AppImage

mkdir -p ../out/
generate_type2_appimage

########################################################################
# Upload the AppDir
########################################################################

transfer ../out/*
echo "AppImage has been uploaded to the URL above; use something like GitHub Releases for permanent storage"
