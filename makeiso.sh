#!/bin/sh
# Author: Naoki OKAMURA (Nyarla) <nyarla[ at ]thotep.net>
# Author: Tukiyo Miidera (tukiyo3) <tukiyo3[ at ]gmail.com>
#
# Usage: ./makeiso.sh
#
# Unlicense: This script is under the public domain.
# Requires: gzip tar mkisofs syslinux curl (or axel) ssh
set -eu

# set your ssh public key.
SSH_LOGIN_KEY="$HOME/.ssh/id_rsa.pub"
STARTUP_COMMAND_1=""
STARTUP_COMMAND_2=""
STARTUP_COMMAND_3=""

# environment
BINDIR=`cd $(dirname $0) && pwd`
COREOS_VERSION=${COREOS_VERSION:="master"}
WORKDIR=$BINDIR/${COREOS_VERSION}
CURL=${CURL:="curl -s"} 
SYSLINUX_BASE_URL="ftp://www.kernel.org/pub/linux/utils/boot/syslinux/"
SYSLINUX_NAME="syslinux-6.02"
SYSLINUX_SYS_DIR="$WORKDIR/iso/syslinux/"
SYSLINUX_ISO_DIR="$WORKDIR/iso/isolinux/"
BOOT_ENV=${BOOT_ENV:="bios"}
#BOOT_ENV=${BOOT_ENV:="efi64"}
COREOS_BASE_URL="http://storage.core-os.net/coreos/amd64-generic"
COREOS_VERSION_URL="${COREOS_BASE_URL}/${COREOS_VERSION}"

check_login_key() {
    if [ ! -r $SSH_LOGIN_KEY ];then
        echo "[quit] ${SSH_LOGIN_KEY} not found. Please run ssh-keygen to generate keys."
        return 1
    fi
}

echo_job() {
    echo "-----> $1"
}

initialize_working_directory() {
    echo_job "Initialize working directory"
    if [ ! -d $WORKDIR ];then
        mkdir -p $WORKDIR
    fi
    cd $WORKDIR
    mkdir -p iso/coreos
    mkdir -p iso/syslinux
    mkdir -p iso/isolinux
}

get_coreos_version_txt() {
    cd $WORKDIR
    echo_job "CoreOS version"
    $CURL -o version.txt "${COREOS_VERSION_URL}/version.txt"
    cat version.txt
}

get_coreos_kernel() {
    cd $WORKDIR
    echo_job "Download CoreOS's kernel"
    if [ ! -e iso/coreos/vmlinuz ]; then
      $CURL -o iso/coreos/vmlinuz "${COREOS_VERSION_URL}/coreos_production_pxe.vmlinuz"
    fi
}

get_coreos_initrd() {
    cd $WORKDIR
    echo_job "Download CoreOS's initrd"
    if [ ! -e iso/coreos/cpio.gz ]; then
      $CURL -o iso/coreos/cpio.gz "${COREOS_VERSION_URL}/coreos_production_pxe_image.cpio.gz"
    fi
}

is_not_osx() {
    if [ "`uname -s`" != "Dawrin" ];then
         return "true"
    fi
    return "false"
}

customize_rootimage() {
    cd $WORKDIR
    echo_job "customize rootimage"
    cd iso/coreos
    mkdir -p usr/share/oem
    cat<<EOF > usr/share/oem/run
#!/bin/sh
# Place your OEM run commands here...
${STARTUP_COMMAND_1}
${STARTUP_COMMAND_2}
${STARTUP_COMMAND_3}
EOF
    chmod +x usr/share/oem/run
    gzip -d cpio.gz
    find usr | cpio -o -A -H newc -O cpio
    gzip cpio
    rm -rf usr/share/oem
    cd $WORKDIR
}

get_syslinux() {
    cd $WORKDIR
    echo_job "Download syslinux and copy iso directory"
    if [ ! -e ${SYSLINUX_NAME} ]; then
        $CURL -o  ${SYSLINUX_NAME}.tar.gz ${SYSLINUX_BASE_URL}/${SYSLINUX_NAME}.tar.gz
    fi
    tar zxf ${SYSLINUX_NAME}.tar.gz

    cd ${SYSLINUX_NAME}/${BOOT_ENV}
    cp com32/chain/chain.c32 $SYSLINUX_SYS_DIR
    cp com32/lib/libcom32.c32 $SYSLINUX_SYS_DIR
    cp com32/libutil/libutil.c32 $SYSLINUX_SYS_DIR
    cp memdisk/memdisk $SYSLINUX_SYS_DIR

    cp core/isolinux.bin $SYSLINUX_ISO_DIR
    cp com32/elflink/ldlinux/ldlinux.c32 $SYSLINUX_ISO_DIR
    cd $WORKDIR
}
 
make_isolinux_cfg() {
    cd $WORKDIR
    echo_job "Make isolinux.cfg file"
    echo "INCLUDE /syslinux/syslinux.cfg" > $SYSLINUX_ISO_DIR/isolinux.cfg
}

make_syslinux_cfg() {
    cd $WORKDIR
    echo_job "Make syslinux.cfg file"
    cat << EOF > $SYSLINUX_SYS_DIR/syslinux.cfg
default coreos
prompt 1
timeout 15

label coreos
    kernel /coreos/vmlinuz
    append initrd=/coreos/cpio.gz root=squashfs: state=tmpfs: sshkey="$(cat ${SSH_LOGIN_KEY})"
EOF
}

make_iso() {
    cd $WORKDIR
    echo_job "Make ISO file"
    cd $WORKDIR/iso
    mkisofs -v -l -r -J -quiet \
      -o ${BINDIR}/CoreOS.${COREOS_VERSION}.iso \
      -b isolinux/isolinux.bin \
      -c isolinux/boot.cat \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      .
    if [ "`which isohybrid`" != "" ];then
        isohybrid ${BINDIR}/CoreOS.${COREOS_VERSION}.iso
    else
        echo "[info] isohybrid not found. skip"
    fi
    ls -lh ${BINDIR}/CoreOS.${COREOS_VERSION}.iso
    cd $WORKDIR
}

cleanup() {
    set -u
    cd $WORKDIR
    echo_job "Cleanup"
    cd $BINDIR
    rm -rf $WORKDIR
}

# main
check_login_key
initialize_working_directory
get_coreos_version_txt
get_coreos_kernel
get_coreos_initrd
if [ is_not_osx = "true" ];then
     # osx not supported cpio append (-A)
     customize_rootimage
fi
get_syslinux
make_isolinux_cfg
make_syslinux_cfg
make_iso
#cleanup
 
echo_job "[Finish]"
echo "iso boot then"
echo " 1. ssh core@<ip>"
echo " 2. read http://qiita.com/tukiyo3/items/a0f54f25a986a6e58d83"
