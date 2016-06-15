# Ubuntinator

A set of scripts to automate the building of a minimal Ubuntu system
based on Ubuntu Base, which is described here: https://wiki.ubuntu.com/Core.

The system is installed onto a single partition.

X-Windows is not installed. A few useful utilities such as 'curl', 'sudo'
and 'wpasupplicant' are installed. An SSH server and client is installed.
Any of these can be removed, if preferred, after the installation process
has completed.

The scripts make an attempt to set up networking using DHCP. Anything more
complicated than a simple wired network connection will likely require more
work after installation.


## Read This!

So far, this has only been tested in a VirtualBox environment running Puppy
Linux and installing onto a virtual disk. Exercise extereme caution - making
sure that you understand what the script do - when using on a important system.

**WARNING: The scripts install a Grub bootloader onto the disk holding the
newly created root partition, which may render other operating systems on a
multiboot setup unbootable.**

**WARNING: Choosing the wrong partition to install to could permanently erase
important data, or entire operating systems.**


## Limitations of testing

This is a new project. At this point, only installation of the 
Intel 64-bit/AMD64 variant of Xenial (Ubuntu 16.04) has been tested.


## Usage

1. Copy the files in `files` to the system you wish to install *from*. We have
found 'live' CD distributions such as Puppy Linux useful for this. The scripts 
need working network access to download files from the Internet. The
`make_pkg.sh` script, when executed from the top-level directory, will
create a tarball of those files for convenient copying.

2. Create a new partition that you wish to install *to*, or select an existing
empty partition. EXT3 and EXT4 file systems are supported. Others may be,
but this has not been tested. The partiton must be empty (a `lost+found`
directory in the top level is OK though).

3. Start the process by running `phase1.sh` from the directory it resides in.
Follow the instructions carefully. When prompted for a partition to install 
*to*, **ensure you don't chose a partition with valuable data on it**. The
script *should* refuse to install to a non-empty partition, but that has not
been extensively tested, so it would unwise to rely on it.

4. The `phase1.sh` script will extract the Ubuntu base root file system to a 
temporary area, and `chroot` to it. It will then automatically run `phase2.sh`
under the chroot - **the `phase2.sh` script should never need to be run
manually**. There is actually nothing for you to do for this step!

5. Boot the new system, and log in with the root credentials you will have 
provided during the steps above. The new system is still not quite complete,
so run the `phase3.sh` script to complete the process. It will be located in
`/usr/local/ubuntinator` on the new system.

6. Reboot into your new system and enjoy!


## Cleaning up

Normally, the `phase1.sh` script will clean up after iteself. However, if a 
failure occurs, it may leave the temporary choot files in place. Before you 
delete those, note that`phase1.sh` script mounts `/dev` and `/proc` to areas
within the  chroot, to make installation possible. Make sure you unmount those
first, otherwise recursively deleting the chroot can delete vital files
within `/dev` and `/proc`, making your current system become unstable and then
crash. Rebooting should  however, fix this, as those file will be regenerated.
