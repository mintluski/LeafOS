================================================================
  LeafOS v1.0-LTS - Documentation (English)
================================================================

1. OVERVIEW
-----------
LeafOS is a lightweight Linux distribution based on BusyBox and
the Alpine Linux package ecosystem. It is designed for virtual
machines, embedded systems, and minimal environments.

  - Kernel: Linux 6.19.6
  - Init: Custom shell-based init
  - Shell: BusyBox ash
  - Package Manager: Alpine APK (25,000+ packages)
  - Filesystem: ext2
  - Bootloader: GRUB 2

2. HOW TO BOOT
--------------
a) From ISO (Live Mode):
   qemu-system-x86_64 -m 256 -cdrom leafos-v1.0-LTS.iso \
       -net nic,model=e1000 -net user -nographic

b) From installed disk:
   qemu-system-x86_64 -m 256 -hda leafos-disk.qcow2 \
       -net nic,model=e1000 -net user -nographic

c) With graphical display:
   qemu-system-x86_64 -m 256 -cdrom leafos-v1.0-LTS.iso \
       -net nic,model=e1000 -net user

3. HOW TO INSTALL
-----------------
a) Boot from the ISO
b) At the shell prompt, type: leafos-install
c) Follow the interactive prompts:
   - Select target disk (e.g., /dev/sda)
   - Choose keyboard layout (default: us)
   - Confirm installation
d) The installer will:
   - Partition the disk
   - Format as ext2
   - Copy the system files
   - Install GRUB bootloader
   - Configure the system
e) Remove the ISO and reboot

For automated installation, create /autoinstall.conf:
   AUTO_MODE=1
   AUTO_DISK="/dev/sda"
   AUTO_KEYBOARD="us"

4. HOW TO INSTALL PACKAGES
---------------------------
LeafOS uses Alpine Linux's APK package manager.

  # Update package index
  apk update

  # Search for a package
  apk search <name>

  # Install a package
  apk add <package>

  # Remove a package
  apk del <package>

  # List installed packages
  apk info

  # Install without cache
  apk add --no-cache <package>

Examples:
  apk add curl        # HTTP client
  apk add htop        # Process viewer
  apk add nano        # Text editor
  apk add openssh     # SSH server/client
  apk add python3     # Python 3

5. SYSTEM COMMANDS
------------------
  leafos-help      Show available commands
  leafos-info      Show system information
  leafos-version   Show version
  leafos-install   Install to disk

6. SYSTEM RECOVERY
------------------
If the system fails to boot:

a) Boot from ISO in rescue mode:
   - Select "LeafOS v1.0-LTS (Rescue Shell)" from GRUB menu

b) Mount the installed system:
   mount /dev/sda1 /mnt
   
c) Fix issues:
   - Edit /mnt/etc/fstab if mount issues
   - Edit /mnt/init if init issues
   - Check /mnt/boot/grub/grub.cfg for boot config

d) Reinstall bootloader:
   - Boot from ISO
   - Mount disk: mount /dev/sda1 /mnt
   - Copy GRUB: dd if=/usr/lib/grub/i386-pc/boot.img of=/dev/sda bs=440 count=1
   - Copy core: dd if=/usr/lib/grub/i386-pc/core_tiny.img of=/dev/sda bs=512 seek=1

e) Chroot into installed system:
   mount -t proc proc /mnt/proc
   mount -t sysfs sysfs /mnt/sys
   mount -o bind /dev /mnt/dev
   chroot /mnt /bin/sh

7. NETWORK CONFIGURATION
-------------------------
  - DHCP is configured automatically via udhcpc
  - DNS resolvers: /etc/resolv.conf
  - In QEMU, use: -net nic,model=e1000 -net user

8. VERSION INFORMATION
----------------------
  Version:  v1.0-LTS
  Codename: LeafOS
  Release:  Long-Term Support
  Kernel:   6.19.6
  BusyBox:  1.31.1
  APK:      2.14.6

================================================================
  LeafOS v1.0
================================================================
