#!/bin/sh
# ============================================================
# LeafOS v1.0-LTS Installer
# Interactive installer for disk-based installation
# ============================================================

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
mount -t devtmpfs none /dev 2>/dev/null
mknod /dev/sda b 8 0
mknod /dev/sda1 b 8 1
mount -t proc none /proc
mount -t sysfs none /sys
mdev -s
for d in /mnt /mnt/install /mnt/root /mnt/sysroot; do
  mkdir -p "$d"
done

# Colors
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

msg() { printf "${GREEN}[INFO]${RESET} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${RESET} %s\n" "$1"; }
err() { printf "${RED}[ERROR]${RESET} %s\n" "$1"; }
ask() { printf "${CYAN}[?]${RESET} %s " "$1"; }
step() { printf "${BOLD}${GREEN}>>> %s${RESET}\n" "$1"; }

# ---- Detect automated mode ----
AUTO_MODE=0
AUTO_DISK=""
AUTO_KEYBOARD="us"

if [ -f /autoinstall.conf ]; then
    . /autoinstall.conf
    AUTO_MODE=1
    msg "Automated mode detected (autoinstall.conf)"
fi

# ---- Welcome screen ----
clear 2>/dev/null
echo ""
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║        LeafOS v1.0-LTS Installer              ║"
echo "  ╠═══════════════════════════════════════════════╣"
echo "  ║  This installer will copy the system to disk  ║"
echo "  ║  and configure it for standalone boot.        ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo ""

# ---- List disks ----
step "Detecting disks and partitions..."
echo ""
echo "  Available devices:"
echo "  ─────────────────────────────────────"
if [ -f /proc/partitions ]; then
    cat /proc/partitions | tail -n +3 | while read major minor blocks name; do
        if [ -n "$name" ]; then
            SIZE_MB=$((blocks / 1024))
            if [ $SIZE_MB -gt 1024 ]; then
                SIZE_GB=$(echo "$SIZE_MB 1024" | awk '{printf "%.1f", $1/$2}')
                printf "  /dev/%-10s  %s GB\n" "$name" "$SIZE_GB"
            elif [ $SIZE_MB -gt 0 ]; then
                printf "  /dev/%-10s  %d MB\n" "$name" "$SIZE_MB"
            fi
        fi
    done
fi
echo "  ─────────────────────────────────────"
echo ""

# ---- Select target disk ----
if [ "$AUTO_MODE" -eq 1 ] && [ -n "$AUTO_DISK" ]; then
    TARGET_DISK="$AUTO_DISK"
    msg "Disk selected automatically: $TARGET_DISK"
else
    ask "Target disk for installation (e.g., /dev/sda):"
    read TARGET_DISK
    [ -z "$TARGET_DISK" ] && { err "No disk specified. Aborting."; exec /bin/sh; }
fi

# Validate disk exists
if [ ! -b "$TARGET_DISK" ]; then
    err "Device $TARGET_DISK not found."
    exec /bin/sh
fi

# ---- Keyboard layout ----
if [ "$AUTO_MODE" -eq 1 ]; then
    KEYBOARD="$AUTO_KEYBOARD"
else
    echo ""
    msg "Available layouts: us, br-abnt2, uk, de, fr, es"
    ask "Keyboard layout [us]:"
    read KEYBOARD
    [ -z "$KEYBOARD" ] && KEYBOARD="us"
fi
msg "Keyboard: $KEYBOARD"

# ---- Confirmation ----
echo ""
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║  Installation Summary                         ║"
echo "  ╠═══════════════════════════════════════════════╣"
printf "  ║  Disk:     %-35s║\n" "$TARGET_DISK"
printf "  ║  Keyboard: %-35s║\n" "$KEYBOARD"
echo "  ║                                               ║"
echo "  ║  WARNING: ALL DATA ON DISK WILL BE ERASED!    ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo ""

if [ "$AUTO_MODE" -eq 0 ]; then
    ask "Proceed with installation? (yes/no):"
    read CONFIRM
    case "$CONFIRM" in
        yes|YES|y|Y) ;;
        *) msg "Installation cancelled."; exec /bin/sh ;;
    esac
fi

# ============================================================
# INSTALLATION BEGINS
# ============================================================
echo ""
step "Starting installation..."
echo ""

# ---- Step 1: Partition disk ----
step "Step 1/6: Partitioning disk $TARGET_DISK..."

# Create a single bootable partition using entire disk
# Compatible with BusyBox fdisk
printf "o\nn\np\n1\n\n\na\n1\nw\n" | fdisk "$TARGET_DISK" 2>/dev/null
sleep 2

# Determine partition name
TARGET_PART="${TARGET_DISK}1"
WAIT=0
while [ ! -b "$TARGET_PART" ] && [ $WAIT -lt 10 ]; do
    for p in "${TARGET_DISK}1" "${TARGET_DISK}p1"; do
        [ -b "$p" ] && { TARGET_PART="$p"; break 2; }
    done
    sleep 1
    WAIT=$((WAIT + 1))
done

if [ ! -b "$TARGET_PART" ]; then
    err "Partition not found after partitioning."
    exec /bin/sh
fi
msg "Partition created: $TARGET_PART"

# ---- Step 2: Format partition ----
step "Step 2/6: Formatting $TARGET_PART as ext2..."
mke2fs "$TARGET_PART" 2>/dev/null || { err "Failed to format partition."; exec /bin/sh; }
msg "Partition formatted successfully."

# ---- Step 3: Mount and copy system ----
step "Step 3/6: Copying system files..."
DEST="/mnt/install"
mkdir -p "$DEST"
mount "$TARGET_PART" "$DEST" || { err "Failed to mount partition."; exec /bin/sh; }

# Copy rootfs using tar
cd /
tar cf - \
    --exclude='./proc/*' \
    --exclude='./sys/*' \
    --exclude='./dev/*' \
    --exclude='./tmp/*' \
    --exclude='./run/*' \
    --exclude='./mnt/*' \
    . 2>/dev/null | tar xf - -C "$DEST" 2>/dev/null
msg "System files copied."

# ---- Step 4: Configure installed system ----
step "Step 4/6: Configuring system..."

mkdir -p "$DEST/proc" "$DEST/sys" "$DEST/dev" "$DEST/tmp" "$DEST/run"
mkdir -p "$DEST/mnt" "$DEST/boot" "$DEST/root"

echo "KEYMAP=$KEYBOARD" > "$DEST/etc/keymap.conf"

cat > "$DEST/etc/fstab" << FSTABEOF
# /etc/fstab - LeafOS v1.0-LTS
$TARGET_PART  /        ext2    defaults,noatime  0  1
proc          /proc    proc    defaults          0  0
sysfs         /sys     sysfs   defaults          0  0
devtmpfs      /dev     devtmpfs defaults         0  0
tmpfs         /tmp     tmpfs   defaults          0  0
tmpfs         /run     tmpfs   defaults          0  0
FSTABEOF

touch "$DEST/etc/leafos-installed"
cp /etc/resolv.conf "$DEST/etc/resolv.conf" 2>/dev/null
cp /etc/udhcpc.script "$DEST/etc/udhcpc.script" 2>/dev/null
chmod +x "$DEST/etc/udhcpc.script" 2>/dev/null
rm -f "$DEST/autoinstall.conf"

msg "System configured."

# ---- Step 5: Install bootloader ----
step "Step 5/6: Installing bootloader..."

mkdir -p "$DEST/boot/grub"

# Copy kernel and initramfs from CD if available
KERNEL_COPIED=0
for cdrom in /dev/sr0 /dev/cdrom; do
    if [ -b "$cdrom" ]; then
        mkdir -p /mnt/cdrom
        mount -o ro "$cdrom" /mnt/cdrom 2>/dev/null
        if [ -f /mnt/cdrom/boot/LeafOS/vmlinuz ]; then
            cp /mnt/cdrom/boot/LeafOS/vmlinuz "$DEST/boot/vmlinuz"
            msg "Kernel copied from installation media."
            KERNEL_COPIED=1
        fi
        if [ -f /mnt/cdrom/boot/LeafOS/initramfs.gz ]; then
            cp /mnt/cdrom/boot/LeafOS/initramfs.gz "$DEST/boot/initramfs.gz"
            msg "Initramfs copied from installation media."
        fi
        umount /mnt/cdrom 2>/dev/null
        break
    fi
done

if [ "$KERNEL_COPIED" -eq 0 ]; then
    [ -f /boot/vmlinuz ] && cp /boot/vmlinuz "$DEST/boot/vmlinuz"
    [ -f /boot/initramfs.gz ] && cp /boot/initramfs.gz "$DEST/boot/initramfs.gz"
fi

# Create GRUB config
cat > "$DEST/boot/grub/grub.cfg" << GRUBEOF
set timeout=3
set default=0
serial --unit=0 --speed=115200
terminal_input console serial
terminal_output console serial

insmod part_msdos
insmod ext2
set root=(hd0,msdos1)

menuentry "LeafOS v1.0-LTS" {
    set root=(hd0,msdos1)
    linux /boot/vmlinuz root=$TARGET_PART console=tty0 console=ttyS0,115200 rw quiet loglevel=3
    initrd /boot/initramfs.gz
}

menuentry "LeafOS v1.0-LTS (Recovery)" {
    set root=(hd0,msdos1)
    linux /boot/vmlinuz root=$TARGET_PART console=tty0 console=ttyS0,115200 rw
    initrd /boot/initramfs.gz
}

menuentry "LeafOS v1.0-LTS (Rescue Shell)" {
    set root=(hd0,msdos1)
    linux /boot/vmlinuz console=tty0 console=ttyS0,115200 rdinit=/bin/sh
    initrd /boot/initramfs.gz
}
GRUBEOF

# Copy GRUB modules to installed system
if [ -d /usr/lib/grub/i386-pc ]; then
    mkdir -p "$DEST/boot/grub/i386-pc"
    cp /usr/lib/grub/i386-pc/*.mod "$DEST/boot/grub/i386-pc/" 2>/dev/null
    cp /usr/lib/grub/i386-pc/*.lst "$DEST/boot/grub/i386-pc/" 2>/dev/null
    cp /usr/lib/grub/i386-pc/boot.img "$DEST/boot/grub/i386-pc/" 2>/dev/null

    # Create embedded GRUB config for core.img
    GRUB_EARLY=$(mktemp)
    cat > "$GRUB_EARLY" << 'EARLYEOF'
set root=(hd0,msdos1)
set prefix=(hd0,msdos1)/boot/grub
normal
EARLYEOF

    # Determine MBR gap size (sectors between MBR and first partition)
    # BusyBox fdisk output: /dev/sda1 * 63 1048575 ...
    PART_START=""
    FDISK_LINE=$(fdisk -l "$TARGET_DISK" 2>/dev/null | grep "${TARGET_PART}")
    if [ -n "$FDISK_LINE" ]; then
        # Try to extract start sector (handle * for bootable flag)
        PART_START=$(echo "$FDISK_LINE" | awk '{for(i=2;i<=NF;i++){if($i ~ /^[0-9]+$/){print $i; exit}}}')
    fi
    [ -z "$PART_START" ] && PART_START=63
    GAP_BYTES=$(( (PART_START - 1) * 512 ))
    msg "MBR gap: $GAP_BYTES bytes (partition starts at sector $PART_START)"

    # Use pre-built core images
    GRUB_INSTALLED=0

    # Try full core first (includes normal module)
    if [ -f /usr/lib/grub/i386-pc/core_full.img ]; then
        CORE_SIZE=$(wc -c < /usr/lib/grub/i386-pc/core_full.img)
        if [ "$CORE_SIZE" -le "$GAP_BYTES" ]; then
            dd if=/usr/lib/grub/i386-pc/boot.img of="$TARGET_DISK" bs=440 count=1 conv=notrunc 2>/dev/null
            dd if=/usr/lib/grub/i386-pc/core_full.img of="$TARGET_DISK" bs=512 seek=1 conv=notrunc 2>/dev/null
            msg "GRUB bootloader installed to MBR (full, $CORE_SIZE bytes)."
            GRUB_INSTALLED=1
        fi
    fi

    # If full core doesn't fit, try tiny core
    if [ "$GRUB_INSTALLED" -eq 0 ] && [ -f /usr/lib/grub/i386-pc/core_tiny.img ]; then
        CORE_SIZE=$(wc -c < /usr/lib/grub/i386-pc/core_tiny.img)
        if [ "$CORE_SIZE" -le "$GAP_BYTES" ]; then
            dd if=/usr/lib/grub/i386-pc/boot.img of="$TARGET_DISK" bs=440 count=1 conv=notrunc 2>/dev/null
            dd if=/usr/lib/grub/i386-pc/core_tiny.img of="$TARGET_DISK" bs=512 seek=1 conv=notrunc 2>/dev/null
            msg "GRUB bootloader installed to MBR (compact, $CORE_SIZE bytes)."
            GRUB_INSTALLED=1
        fi
    fi

    if [ "$GRUB_INSTALLED" -eq 0 ]; then
        warn "Could not install GRUB to MBR."
        warn "Boot via ISO with root=$TARGET_PART parameter."
    fi
    rm -f "$GRUB_EARLY"
else
    warn "GRUB files not found in live system."
    warn "Boot via ISO with root=$TARGET_PART parameter."
fi

msg "Bootloader configured."

# ---- Step 6: Finalize ----
step "Step 6/6: Finalizing installation..."
sync
umount "$DEST" 2>/dev/null

echo ""
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║     INSTALLATION COMPLETED SUCCESSFULLY!      ║"
echo "  ╠═══════════════════════════════════════════════╣"
printf "  ║  System:    LeafOS v1.0-LTS                  ║\n"
printf "  ║  Partition: %-35s║\n" "$TARGET_PART"
printf "  ║  Keyboard:  %-35s║\n" "$KEYBOARD"
echo "  ║                                               ║"
echo "  ║  Remove the installation media and reboot.    ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo ""

if [ "$AUTO_MODE" -eq 1 ]; then
    msg "Automated mode: shutting down..."
    sleep 2
    poweroff -f 2>/dev/null
    halt -f 2>/dev/null
    exit 0
else
    ask "Press ENTER to reboot, or 's' for shell:"
    read CHOICE
    [ "$CHOICE" = "s" ] && exec /bin/sh
    reboot -f 2>/dev/null || exec /bin/sh
fi
