#!/bin/bash

# The USB Creation was taken from this reddit comment: 
# https://www.reddit.com/r/MacOS/comments/17nrsum/comment/lrr0pv8/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
# This is just a wrapper script that can be used to also download the DMG file and to automate the usb creation.

# Declaring download locations

lion="https://updates.cdn-apple.com/2021/macos/041-7683-20210614-E610947E-C7CE-46EB-8860-D26D71F0D3EA/InstallMacOSX.dmg"
mountainLion="https://updates.cdn-apple.com/2021/macos/031-0627-20210614-90D11F33-1A65-42DD-BBEA-E1D9F43A6B3F/InstallMacOSX.dmg"
yosemite="http://updates-http.cdn-apple.com/2019/cert/061-41343-20191023-02465f92-3ab5-4c92-bfe2-b725447a070d/InstallMacOSX.dmg"
elCapitan="http://updates-http.cdn-apple.com/2019/cert/061-41424-20191024-218af9ec-cf50-4516-9011-228c78eda3d2/InstallMacOSX.dmg"
sierra="http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg"
# ...Anything higher than that goes to the app store. defo need to see if I can still just curl it down
# Also this is the default pkgdir, change it if you dare
pkgDir="./osx.pkg"


echo "Welcome to the legacy OSX USB Creator!"
echo "Commands by u/FarConcentrate3824 on reddit, everything else by eveee00 on github"
echo "======================================"

# USB selection
echo "First, I need the name of the USB you want the installer on. I would format the USB for you, but I currently can't."
echo "I'll launch Disk utility for you in a second. Format your USB as  \"MacOS extended (journaled)\" and come back here"
sleep 2
open /System/Applications/Utilities/Disk\ Utility.app

while true; do
    echo "Enter the name of the USB (Or press \"enter\" to use \"KEY\"):"
    read usbName

    # Set default USB name
    if [ -z "$usbName" ]; then
        usbName="KEY"
    fi

    echo "You have selected $usbName, is that right? (Yy/Nn)"
    read usbYesNo

    # Check user confirmation
    if [[ "$usbYesNo" == "Y" || "$usbYesNo" == "y" || "$usbYesNo" == "Yes" || "$usbYesNo" == "yes" ]]; then
        echo "USB name: $usbName"
        break
    elif [[ "$usbYesNo" == "N" || "$usbYesNo" == "n" || "$usbYesNo" == "No" || "$usbYesNo" == "no" ]]; then
        echo "Let's try again."
    else
        echo "Invalid response. Please answer with Y/y/Yes or N/n/No."
    fi
done


echo "Alright, let's pick the OSX version you want to install."
while true; do
    echo "Do you have a OSX 10.7-10.12 Installer downloaded (Yy/Nn)?"
    read installerDlYesNo

    # Ask if user already has an installer
    if [[ "$installerDlYesNo" == "Y" || "$installerDlYesNo" == "y" || "$installerDlYesNo" == "Yes" || "$installerDlYesNo" == "yes" ]]; then
        # Sets the DMG path to extract later
        echo "Drag the installer DMG into this window"
        read DMGDir
        break
    
    elif [[ "$installerDlYesNo" == "N" || "$installerDlYesNo" == "n" || "$installerDlYesNo" == "No" || "$installerDlYesNo" == "no" ]]; then
        # Version picker
        echo "Alright, let's download an installer."
        echo "Select the OSX version to download:"

        echo "1) OS X 10.7 (Lion)"
        echo "2) OS X 10.8 (Mountain Lion)"
        echo "3) OS X 10.10 (Yosemite)"
        echo "4) OS X 10.11 (El Capitan)"
        echo "5) OS X 10.12 (Sierra)"
        echo "Enter the number corresponding to your choice:"
        read osChoice
        case $osChoice in
            1)
                downloadUrl=$lion
                ;;
            2)
                downloadUrl=$mountainLion
                ;;
            3)
                downloadUrl=$yosemite
                ;;
            4)
                downloadUrl=$elCapitan
                ;;
            5)
                downloadUrl=$sierra
                ;;
            *)
                echo "Invalid response. Please try again."
                ;;
        esac

        # Finally DL installer
        echo "Downloading the installer..."
        curl -o osx.dmg "$downloadUrl"
        if [ $? -eq 0 ]; then
            echo "Download completed successfully."
            DMGDir="./osx.dmg"
        else
            echo "Download failed.  Check that your cURL installation is correct and try again."
            exit 1
        fi
    else
        echo "Invalid response. Please answer with Y/y/Yes or N/n/No."
    fi
done

# Create USB
echo "Creating installer on drive $usbName"
echo "Attaching DMG..."
hdiutil attach $DMGDir -noverify -nobrowse -mountpoint /Volumes/osx
echo "Copying PKG..."
cp /Volumes/osx/InstallMacOSX.pkg $pkgDir

echo "Expanding the PKG file"
echo "This may take some time..."
pkgutil --expand $pkgDir ./Installer
echo "Finished expanding PKG"

echo "Going into the PKG..."
cd ./Installer/InstallMacOSX.pkg

echo "Extracting Payload..."
sleep 2
tar -xvf Payload

echo "Copying ESD..."
mkdir ../../esd
mv InstallESD.dmg ../../esd

echo "Building installer..."
sleep 2

hdiutil attach ../../esd/InstallESD.dmg -noverify -nobrowse -mountpoint /Volumes/install_app
hdiutil convert /Volumes/install_app/BaseSystem.dmg -format UDSP -o /tmp/Installer
hdiutil resize -size 8g /tmp/Installer.sparseimage
hdiutil attach /tmp/Installer.sparseimage -noverify -nobrowse -mountpoint /Volumes/install_build
rm -r /Volumes/install_build/System/Installation/Packages
cp -av /Volumes/install_app/Packages /Volumes/install_build/System/Installation/
cp -av /Volumes/install_app/BaseSystem.chunklist /Volumes/install_build
cp -av /Volumes/install_app/BaseSystem.dmg /Volumes/install_build

echo "Detaching Volumes..."
hdiutil detach /Volumes/install_app
hdiutil detach /Volumes/install_build

echo "Resizing and converting SparseImage"
hdiutil resize -size `hdiutil resize -limits /tmp/Installer.sparseimage | tail -n 1 | awk '{print $ 1}' `b /tmp/Installer.sparseimage
hdiutil convert /tmp/Installer.sparseimage -format UDZO -o /tmp/Installer

echo "Moving installer..."
mkdir ../../dmg
mv /tmp/Installer.dmg ../../dmg

echo "Starting installation on $usbName"

sleep 1
echo "3"
sleep 1
echo "2"
sleep 1
echo "1"
sleep 1

sudo asr restore --source ../../dmg/Installer.dmg --target /Volumes/KEY --noprompt --noverify --erase

echo "=========================="
echo "Done :3"
echo "The Installer should be on your desktop. Check the output for any errors."