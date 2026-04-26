cd root
find . | cpio -o -H newc | gzip -9 > ../iso_root/boot/LeafOS/initramfs.gz
cd ..
grub-mkrescue -o LeafOS.iso iso_root/
