#!/bin/bash

# Script to unpack the debian iso, inject the preseed.cfg file to it and repack it

## Argument parsing ##

# Variable to store the location of the "factory" debian iso file
ORIGINAL_ISO=$1

# Variable to store the location of the preseed.cfg file
PRESEED_FILE=$2

# Filename for the generated ISO
PRESEED_ISO="preseed-debian12-amd64.iso"

# Create mountpoint for Original ISO in /media
if [ ! -d /media/debian-iso ]; then
	echo "Creating ISO mountpoint at /media/debian-iso"
	mkdir /media/debian-iso
fi

# Create temporary directory for ISO files
if [ ! -d ./temp-iso-files ]; then
        echo "Creating ISO mountpoint at /media/debian-iso"
        mkdir ./temp-iso-files
fi

# Mount the original debian ISO as a loopback device
echo "Mounting the original ISO as a loopback device"
mount -o loop -t iso9660 $ORIGINAL_ISO /media/debian-iso

# Copy all the files to a temp directory
cp -vrT /media/debian-iso temp-iso-files/

# Unmount the original installer ISO
echo "Unmounting ISO from /media/debian-iso"
umount /media/debian-iso

# Delete temporary mountpoint
echo "Deleting directory: /media/debian-iso"
rm -r /media/debian-iso

# Temporarily give write permission to user on everything
echo "Applying write permissions to all installer files"
chmod +w -R ./temp-iso-files/

# Copy preseed.cfg inside the installer files
echo "Copying preseed.cfg inside the installer files"
cp -v $PRESEED_FILE ./temp-iso-files/

# Modify isolinux/isolinux.cfg
echo "Modifying isolinux/isolinux.cfg"
sed -i 's/default vesamenu.c32/default auto/g' temp-iso-files/isolinux/isolinux.cfg

# Modify isolinux/adtxt.cfg
echo "Modifying isolinux/adtxt.cfg"
sed -i 's/append auto\=true/append auto=true file=\/cdrom\/preseed.cfg/g' temp-iso-files/isolinux/adtxt.cfg

# Recalculate md5 hashes since modifications were made to specific files
echo "Recalculating MD5 hashes"
cd temp-iso-files/
find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt
cd ..

# Remove write permissions for everything
echo "Removing write permissions"
chmod -w -R temp-iso-files/

# Repack everything into an ISO image
echo "Repacking ISO image"
xorriso -as mkisofs -o preseed-debian-12-amd64-netinst.iso -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table temp-iso-files

# Cleanup temporary directory
echo "Deleting ./temp-iso-files/"
rm -r temp-iso-files/
