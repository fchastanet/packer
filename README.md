# Packer - Ubuntu 20.04 minimal Vagrant Box

- [1. VM content](#1-vm-content)
- [2. VM Launch](#2-vm-launch)
  - [2.1. VM Launch requiremnts](#21-vm-launch-requiremnts)
  - [2.2. VM Remote Launch](#22-vm-remote-launch)
- [3. Build](#3-build)
  - [3.1. Build Requirements](#31-build-requirements)
  - [3.2. Build Usage](#32-build-usage)
  - [3.3. Test Image](#33-test-image)
  - [3.4. Deploy image](#34-deploy-image)
    - [3.4.1. Deploy image using vagrant cloud (not recommended)](#341-deploy-image-using-vagrant-cloud-not-recommended)
    - [3.4.2. Deploy image using Amazon S3 (recommended)](#342-deploy-image-using-amazon-s3-recommended)
  - [3.5. Launch Box using vagrant](#35-launch-box-using-vagrant)
    - [Add external configuration](#add-external-configuration)
    - [3.5.1. from Vagrant cloud](#351-from-vagrant-cloud)
    - [3.5.2. from s3 bucket](#352-from-s3-bucket)
    - [3.5.3. by building the image](#353-by-building-the-image)
- [4. Storage disk](#4-storage-disk)
- [5. Resize your storage disk](#5-resize-your-storage-disk)
  - [5.1. Alternative 1 (recommended) : create a new volume](#51-alternative-1-recommended--create-a-new-volume)
  - [5.2. Alternative 2 : Resize fixed size vdi file](#52-alternative-2--resize-fixed-size-vdi-file)
    - [5.2.1. Step 1 : resize the volume](#521-step-1--resize-the-volume)
    - [5.2.2. Step 2 : use gparted live CD](#522-step-2--use-gparted-live-cd)
    - [5.2.3. Step 3 : Resize linux partition](#523-step-3--resize-linux-partition)
- [6. Resize / partition](#6-resize--partition)
  - [6.1. Alternative 1 (recommanded): rebuild the image](#61-alternative-1-recommanded-rebuild-the-image)
  - [6.2. Alternative 2 : use ability of lvm to raise volume size transparently](#62-alternative-2--use-ability-of-lvm-to-raise-volume-size-transparently)
    - [6.2.1. Step 1: create a new virtual disk using virtual box](#621-step-1-create-a-new-virtual-disk-using-virtual-box)
    - [6.2.2. Step 2: attach this new drive as sata drive in your VM](#622-step-2-attach-this-new-drive-as-sata-drive-in-your-vm)
    - [6.2.3. Step 3: identify the drive](#623-step-3-identify-the-drive)
    - [6.2.4. Step 4:create primary partition using whole size](#624-step-4create-primary-partition-using-whole-size)
    - [6.2.5. Step 5: format the new drive as logical volume](#625-step-5-format-the-new-drive-as-logical-volume)
    - [6.2.6. Step6 : mount the volume](#626-step6--mount-the-volume)
- [7. FAQ](#7-faq)
  - [7.1. duplicate directory containing vagrant files](#71-duplicate-directory-containing-vagrant-files)
  - [7.2. error C:/HashiCorp/Vagrant/embedded/mingw64/lib/ruby/2.4.0/resolv.rb:834:in `connect': The requested address is not valid in its context. - connect(2) for "0.0.0.0" port 53 (Errno::EADDRNOTAVAIL)](#72-error-chashicorpvagrantembeddedmingw64libruby240resolvrb834in-connect-the-requested-address-is-not-valid-in-its-context---connect2-for-0000-port-53-errnoeaddrnotavail)
  - [7.3. Host/Guest time sync issue](#73-hostguest-time-sync-issue)
  - [7.4. I already have a box file, and I want to load this box instead of building a new box](#74-i-already-have-a-box-file-and-i-want-to-load-this-box-instead-of-building-a-new-box)
  - [7.5. Mount shared folder](#75-mount-shared-folder)
- [8. License](#8-license)

## 1. VM content

check [ImageDescription.md] file

**Current Ubuntu Version Used**: 20.04

This build configuration installs and configures Ubuntu 20.04 x86_64 server with softwares like docker, git, and then generates a Vagrant box file for VirtualBox.

## 2. VM Launch

### 2.1. VM Launch requiremnts

The following software must be installed/present on your local machine in order to launch the Vagrant box file:

- [Vagrant](http://vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/) (if you want to build the VirtualBox box)
- [AWS-cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html) Amazon console cli in order to download vagrant box, alternatively you can build image using packer see Build requirements section

the following vagrant plugins will be automatically installed during vagrant up

- vagrant-vbguest: allow virtual box guest to be automatically installed during first vm boot
- vagrant-timezone: automatically set host timezone
- vagrant-persistent-storage: allows to create external VDI storage

### 2.2. VM Remote Launch

before launching your VM, see [Storage disk](#storage-disk)

Launch using S3

  DESKTOP="lxde" S3_URL="s3://s3url/exports/" make first-start

Launch using vagrant cloud

  DESKTOP="lxde" make first-start

[Alternatively you can build the image locally](#build)

## 3. Build

### 3.1. Build Requirements

In addition to [VM Launch Requirements](#vm-launch-requirements), the following software must be installed/present on your local machine before you can use Packer to build the Vagrant box file:

- [Packer](http://www.packer.io/)

### 3.2. Build Usage

Make sure all the required softwares (listed above) are installed, then cd to the directory containing this README.md file, and run:

  HEADLESS=true DESKTOP="lxde" make build

After about 40 minutes, Packer should tell you the box was generated successfully.

you can see build logs in logs directory

### 3.3. Test Image

Image are tested in two ways:

- checks correct access with wm without any vagrant plugin nor vm-bootrap.sh
- checks that vm boot up correctly with all vagrant plugins enabled + vm-bootrap.sh intialization

  DESKTOP="lxde" make tests

### 3.4. Deploy image

#### 3.4.1. Deploy image using vagrant cloud (not recommended)

> **Note**: in order to deploy to vagrant cloud, you must provide your token in the file `vagrant.token`

then you can deploy using

  make DESKTOP="lxde" deploy

#### 3.4.2. Deploy image using Amazon S3 (recommended)

Alternatively you can deploy to aws repository using

  make DESKTOP="lxde" S3_BUCKET_URL="s3://s3Url" deploy-s3

don't forget to login to aws before

### 3.5. Launch Box using vagrant

#### Add external configuration

You have the ability to add external configuration.
Files present in confExternal directory will be automatically copied into the home directory.

- you can override .bash_profile, .bashrc, .bash_aliases, ...
- you can add the file .externalConfPostInstall.sh that will be automatically executed at the end of the vm bootstrap process (see scripts-vagrant\vm-bootstrap.sh)

Folder structure example:
/confExternal
├── .aws
│   ├── credentials
├── .bash-tools
│   ├── dbImportProfiles
|   │   ├── myProfile
│   ├── .cliProfile.sh
│   ├── .env
├── .bin
│   ├── myCustomScript
├── .config (.config override, see /conf/.config)
├── .local (.local override, see /conf/.local)
├── .kube
├── .tmuxinator
│   ├── myCustomProfile
├── .bash_aliases
├── .bash_profile
├── .motd
├── .externalConfPostInstall.sh (automatically executed at the end of the vm bootstrap process (see scripts-vagrant\vm-bootstrap.sh))

#### 3.5.1. from Vagrant cloud

the box is available on vagrant cloud, simply use

  DESKTOP="lxde" make first-start

#### 3.5.2. from s3 bucket

simply use

  DESKTOP="lxde" S3_BUCKET_URL="s3://s3Url" make first-start

#### 3.5.3. by building the image

box with lxde desktop manager

  DESKTOP="lxde" make first-start-local

next time, you can just start your initialized vm from virtualbox
no need to use vagrant anymore

## 4. Storage disk

**Usage:** you want to give more space to your home partition

a storage disk is automatically created in your user folder
when vagrant image is started you can eventually change the size **before**
first start by changing these lines in your __Vagrantfile__

You can generate your Vagrantfile by using

  DESKTOP="lxde" make Vagrantfile

Then change the following line in the Vagrantfile (Here disk size is 100GB)

  disk_size = 100 * 1024

## 5. Resize your storage disk

you run out of disk space, first of all **make a backup of your storage disk**, here 2 recipes

### 5.1. Alternative 1 (recommended) : create a new volume

Idea is to create a new volume
mount old volume as secondary in your vm
boot the vm
you will have to copy all your data back to /home/vagrant

### 5.2. Alternative 2 : Resize fixed size vdi file

I suggest you to pass to dynamic file instead as performance gain is not so high with fixed size vdi file

#### 5.2.1. Step 1 : resize the volume

From git bash launch these commands **Note: first change VDI_FILE variable and size variable !!!**

    # change the name of the your vdi file first
    VDI_FILE="@yourfile@.vdi"
    # set it the new size (in MB) => here we set 150GB
    NEW_SIZE=150000
    # go where your vdi file is stored
    cd $HOME
    # backup your vdi file (just in case)
    cp "${VDI_FILE}" "${VDI_FILE%%.*}_$(date +%F)_backup.vdi"
    # resize
    VBoxManage modifyhd "${VDI_FILE}" --resize "${NEW_SIZE}"

#### 5.2.2. Step 2 : use gparted live CD

[http://derekmolloy.ie/resize-a-virtualbox-disk/]

#### 5.2.3. Step 3 : Resize linux partition

Stop gparted live CD and unmount your vdi file
Restart your vm
connect as root on the VM

    # stop services
    service docker stop
    service gdm stop
    # unmount /dev/sdb
    umount -l /home/vagrant
    # deactivate the logical volumes from vps group
    vgchange -d -an vps
    # resize the logical volume to 100% of the new size
    lvextend -l+100%FREE /dev/vps/vps
    # check the volume
    e2fsck -f /dev/vps/vps
    # reactivate the logical volumes from vps group
    vgchange -d -ay vps
    # extend the filesystem on the whole LV
    resize2fs /dev/vps/vps

## 6. Resize / partition

### 6.1. Alternative 1 (recommanded): rebuild the image

change disk_size in ubuntu.pkr.hcl and relaunch the build of image

### 6.2. Alternative 2 : use ability of lvm to raise volume size transparently

**Usage:** you want to give more space to main partition
size of the vm has been limited to 50GB in packer file
here we create a new vdi file, we attach it to the vm and then
we use the ability to attach this disk to lvm in order to raise
the disk capacity

#### 6.2.1. Step 1: create a new virtual disk using virtual box

    # size (in MB) => here we set 100GB
    NEW_SIZE=100000
    VBoxManage createmedium disk --filename packer-dev-env-lxde_2.0.6_extended.vdi --size ${NEW_SIZE} --format VDI --variant Standard

#### 6.2.2. Step 2: attach this new drive as sata drive in your VM

and start your VM

#### 6.2.3. Step 3: identify the drive

go as root

  sudo su

list the drives

  fdisk -l

You should see something like (some information are cut for lisibility)

  ....
  Disk /dev/sda: 48.85 GiB, 52428800000 bytes, 102400000 sectors
  Disk model: VBOX HARDDISK
  ...

  Device       Start       End   Sectors  Size Type
  /dev/sda1     2048      4095      2048    1M BIOS boot
  ...

  Disk /dev/sdb: 9.78 GiB, 10485760000 bytes, 20480000 sectors
  Disk model: VBOX HARDDISK
  ...

  Disk /dev/sdc: 100 GiB, 107374182400 bytes, 209715200 sectors
  Disk model: VBOX HARDDISK
  ...
  Device     Boot Start       End   Sectors  Size Id Type
  /dev/sdc1        2048 209715199 209713152  100G 8e Linux LVM

The drive you search begins with /dev/sd
in my example it is /dev/sdb because there is no device attached
(on others we can see /dev/sdc1, /dev/sda1, ...) and also size matches

#### 6.2.4. Step 4:create primary partition using whole size

sfdisk will warn you if you are using a drive already mounted but be careful
to **change /dev/sdb accordingly to your configuration**

  echo 'start=2048, type=83' | sudo sfdisk /dev/sdb

Runing again __fdisk -l__ should show something like

  Device     Boot Start      End  Sectors  Size Id Type
  /dev/sdb1        2048 20479999 20477952  9.8G 83 Linux

#### 6.2.5. Step 5: format the new drive as logical volume

[I used this documentation to create this tutorial](https://stuff.mit.edu/afs/athena/project/rhel-doc/5/RHEL-5-manual/Cluster_Logical_Volume_Manager/LV_create.html)

**Create a LVM physical volume** on the partition we just created.

  pvcreate /dev/sdb1

**Create volume Group** Now that we have a partition designated and physical volume created we need to create the volume group. Luckily this only takes one command.

  vgcreate vgpool /dev/sdb1

**Create logical volume** that LVM will use:

- -l 100%FREE to use 100% of the space
- -n to name your volume, by convention beggining with lv

  lvcreate -l 100%FREE -n lvname vgpool

**Format and mount** the logical volume

  mkfs -t ext4 /dev/vgpool/lvname

#### 6.2.6. Step6 : mount the volume

**Alternative 1 : in a directory** for independent storage system

  mkdir -p /mnt/name
  mount -t ext4 /dev/vgpool/lvname /mnt/name
  ls -al /mnt/name

**Alternative 2 : extending available volume** to raise capacity of your main parition
see [How to Extend Volume Group and Reduce Logical Volume](https://www.tecmint.com/extend-and-reduce-lvms-in-linux/)

run `pvs`, to check current status

  PV         VG        Fmt  Attr PSize    PFree
  /dev/sda3  ubuntu-vg lvm2 a--    47.82g    0
  /dev/sdb1  vgpool    lvm2 a--     9.76g    0
  /dev/sdc1  vps       lvm2 a--  <100.00g    0

Remove the volume group created before (this alternative does not need it)

  vgremove -f vgpool

Extending Volume Group

  vgextend ubuntu-vg /dev/sdb1

Run `pvs`, we can see that /dev/sdb1 is on ubuntu-vg group
    PV         VG        Fmt  Attr PSize    PFree
  /dev/sda3  ubuntu-vg lvm2 a--    47.82g    0
  /dev/sdb1  ubuntu-vg lvm2 a--     9.76g 9.76g
  /dev/sdc1  vps       lvm2 a--  <100.00g    0

Run `vgs`, we can see that VFree is not 0
  VG        #PV #LV #SN Attr   VSize    VFree
  ubuntu-vg   2   1   0 wz--n-  <57.59g 9.76g
  vps         1   1   0 wz--n- <100.00g    0

Run `lvdisplay` to list which Volume groups are under which Physical Volumes

```
 --- Logical volume ---
  LV Path                /dev/vps/vps
  LV Name                vps
  VG Name                vps
  LV UUID                WXvnzH-PnGh-ExYy-9K8u-Qekc-tFKU-1D3C3O
  LV Write Access        read/write
  LV Creation host, time ubuntu-server, 2020-12-01 09:22:19 +0100
  LV Status              available
  # open                 0
  LV Size                <100.00 GiB
  Current LE             25599
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:1

  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  LV Name                ubuntu-lv
  VG Name                ubuntu-vg
  LV UUID                sRrGwt-ByoG-0QPc-r6yq-Q4Eg-gQgi-BDRYBD
  LV Write Access        read/write
  LV Creation host, time ubuntu-server, 2020-12-01 09:43:12 +0100
  LV Status              available
  # open                 1
  LV Size                47.82 GiB
  Current LE             12243
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0
```

Now we are going to expand the / partition which is __ubuntu-lv__ in our case.
We deduce the LV Path from `lvdisplay` ouput, in this case it is:

  /dev/ubuntu-vg/ubuntu-lv

Next we extend our logical volume

  lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

Finally after Extending, we need to re-size the file-system using

  resize2fs /dev/ubuntu-vg/ubuntu-lv

That's it, congratulations, you have more free space in your root partition !

## 7. FAQ

### 7.1. duplicate directory containing vagrant files

delete the directory .vagrant to avoid to be linked to the old vms

### 7.2. error C:/HashiCorp/Vagrant/embedded/mingw64/lib/ruby/2.4.0/resolv.rb:834:in `connect': The requested address is not valid in its context. - connect(2) for "0.0.0.0" port 53 (Errno::EADDRNOTAVAIL)

replace all occurrences of 0.0.0.0 by localhost in the file
    `C:\HashiCorp\Vagrant\embedded\mingw64\lib\ruby\2.4.0\resolv.rb`

### 7.3. Host/Guest time sync issue

execute this command

    VBoxManage setextradata packer-dev-env-lxde VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled 0

shutdown the vm and restart it

### 7.4. I already have a box file, and I want to load this box instead of building a new box

```bash
DESKTOP="gnome"
BOX_FILE_PATH=output-virtualbox-04-${DESKTOP}/ubuntu-20.04.1-${DESKTOP}.box
BOX_NAME="ubuntu-${DESKTOP}"
VM_NAME="packer-dev-env-${DESKTOP}"

vagrant box remove -f ${BOX_NAME} --all || true
vagrant box add --force --name ${BOX_NAME} "${BOX_FILE_PATH}"
make Vagrantfile
# remove version from Vagrant file
sed -i -e '/^[ \t]*virtualbox.vm.box_version = .*/d' Vagrantfile
# replace vagrant box
sed -i -e "s/^VAGRANT_BOX = .*/VAGRANT_BOX = '${BOX_NAME}'/g" Vagrantfile
# replace VM_NAME
sed -i -e "s/^VM_NAME = .*/VM_NAME = '${VM_NAME}'/g" Vagrantfile

vagrant up
```

### 7.5. Mount shared folder

Vagrantfile defines hostHome as shared folder. In order to mount the folder on linux, just launch the following command:

```bash
sudo mount -t vboxsf hostHome /hostHome
```

## 8. License

MIT license.
