       LeafOS v1.0-LTS                
       Lightweight Linux System        
**Documentation:** [English](root/usr/share/doc/leafos/README-en.txt) | [Português](root/usr/share/doc/leafos/README-pt-BR.txt)

LeafOS is a minimalist Linux distribution built from scratch for virtual machines, embedded systems, and old hardware (1 GB Celeron class).

**Key features:**
- Boots with **512 MB RAM** (1GB recommended)
- Kernel **6.19.6** with PREEMPT_DYNAMIC
- **musl libc** + **BusyBox** shell
- **APK package manager** with 25,000+ Alpine packages
- Live ISO + interactive installer
- Rescue shell included

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM       | 512 MB  | 1GB MB      |
| CPU       | x86_64  | x86_64      |
| Disk      | 100 MB  | 1 GB        |
| Network   | DHCP    | any         |

## Quick Start (QEMU)

```sh
# Download the ISO (link will be added after first release)
# Boot with QEMU (non-graphical)
qemu-system-x86_64 -m 512 -cdrom leafos-v1.0-LTS.iso -nographic

# Boot with graphics
qemu-system-x86_64 -m 512 -cdrom leafos-v1.0-LTS.iso

# Network enabled
qemu-system-x86_64 -m 512 -cdrom leafos-v1.0-LTS.iso \
    -net nic,model=e1000 -net user
```

Installation

Interactive (easy)

1. Boot from ISO
2. Type leafos-install
3. Follow the prompts (disk, keyboard)
4. Reboot

Automated (with autoinstall.conf)

Create a file /autoinstall.conf with:

```
AUTO_MODE=1
AUTO_DISK="/dev/sda"
AUTO_KEYBOARD="us"
```

LeafOS will detect it during boot and install automatically.

Manual (from running system)

```sh
# Replace /dev/sda with your target disk
dd if=/usr/lib/grub/i386-pc/boot.img of=/dev/sda bs=440 count=1
dd if=/usr/lib/grub/i386-pc/core_tiny.img of=/dev/sda bs=512 seek=1
cp -r / /mnt/rootfs/
```

Package Management (APK)

LeafOS uses Alpine's APK. No configuration needed.

```sh
apk update                     # Update package index
apk search <name>              # Search for a package
apk add <package>              # Install package
apk del <package>              # Remove package
apk info                       # List installed packages
apk add --no-cache <package>   # Install without saving cache
```

Useful packages for programming:

```sh
apk add gcc musl-dev make      # C development
apk add nano vim               # Text editors
apk add git                    # Version control
apk add python3                # Python interpreter
apk add openssh                # SSH client/server
```

LeafOS Commands

Command Description
leafos-help Show available commands
leafos-info System information (kernel, RAM, packages)
leafos-version Show version
leafos-install Run installer

System Recovery

If the system fails to boot:

1. Rescue shell: Select "LeafOS (Rescue Shell)" in GRUB
2. Mount installed system: mount /dev/sda1 /mnt
3. Fix bootloader (if needed):
   ```sh
   dd if=/usr/lib/grub/i386-pc/boot.img of=/dev/sda bs=440 count=1
   dd if=/usr/lib/grub/i386-pc/core_tiny.img of=/dev/sda bs=512 seek=1
   ```
4. Chroot for advanced fixes:
   ```sh
   mount -t proc proc /mnt/proc
   mount -t sysfs sysfs /mnt/sys
   mount -o bind /dev /mnt/dev
   chroot /mnt /bin/sh
```
