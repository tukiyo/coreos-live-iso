#!/usr/bin/env bash
# Author: Naoki OKAMURA (Nyarla) <nyarla[ at ]thotep.net>
# Usage:  ./makeiso.sh
# Unlicense: This script is under the public domain.

set -e

# Default configurations
SYSLINUX_VERSION='6.02'
COREOS_VERSION='147.0.1'
BOOT_ENV='bios'
SSH_PUBKEY_PATH=~/.ssh/id_rsa.pub

# Initialze variables
SYSLINUX_BASE_URL="https://www.kernel.org/pub/linux/utils/boot/syslinux"
SYSLINUX_BASENAME="syslinux-$SYSLINUX_VERSION"
SYSLINUX_URL="${SYSLINUX_BASE_URL}/${SYSLINUX_BASENAME}.tar.gz"

COREOS_BASE_URL="http://storage.core-os.net/coreos/amd64-generic"
COREOS_KERN_BASENAME="coreos_production_pxe.vmlinuz"
COREOS_INITRD_BASENAME="coreos_production_pxe_image.cpio.gz"
COREOS_KERN_URL="${COREOS_BASE_URL}/${COREOS_VERSION}/${COREOS_KERN_BASENAME}"
COREOS_INITRD_URL="${COREOS_BASE_URL}/${COREOS_VERSION}/${COREOS_INITRD_BASENAME}"

SSH_PUBKEY=`cat ${SSH_PUBKEY_PATH}`

bindir=`cd $(dirname $0) && pwd`
workdir=$bindir/work

echo "-----> Initialize working directory"
if [ ! -d $workdir ];then
    mkdir -p $workdir
fi;

cd $workdir

mkdir -p iso/coreos
mkdir -p iso/syslinux
mkdir -p iso/isolinux

echo "-----> Download CoreOS's kernel"
curl -o iso/coreos/vmlinuz $COREOS_KERN_URL

echo "-----> Download CoreOS's initrd"
curl -o iso/coreos/cpio.gz $COREOS_INITRD_URL

echo "-----> Download syslinux and copy to iso directory"
curl -O $SYSLINUX_URL
tar zxf ${SYSLINUX_BASENAME}.tar.gz

cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/chain/chain.c32 iso/syslinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/lib/libcom32.c32 iso/syslinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/libutil/libutil.c32 iso/syslinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/memdisk/memdisk iso/syslinux/

cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/core/isolinux.bin iso/isolinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/elflink/ldlinux/ldlinux.c32 iso/isolinux/

echo "-----> Make isolinux.cfg file"
cat<<EOF > iso/isolinux/isolinux.cfg
INCLUDE /syslinux/syslinux.cfg
EOF

echo "-----> Make syslinux.cfg file"
cat<<EOF > iso/syslinux/syslinux.cfg
prompt 0
default coreos

LABEL coreos
KERNEL /coreos/vmlinuz
APPEND initrd=/coreos/cpio.gz root=squashfs: state=tmpfs: sshkey="${SSH_PUBKEY}"
EOF

echo "-----> Make ISO file"
cd iso
mkisofs -v -l -r -J -o ${bindir}/CoreOS.${COREOS_VERSION}.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .

echo "-----> Cleanup"
cd $bindir
rm -rf $workdir

echo "-----> Finished"

