#!/bin/bash

package-cleanup -y --oldkernels --count=1

KERNEL_VERSION=$(ls /lib/modules)

mount -o ro,loop /home/ec2-user/VBoxGuestAdditions.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -f /root/VBoxGuestAdditions.iso

/etc/kernel/postinst.d/vboxadd ${KERNEL_VERSION}

/sbin/depmod ${KERNEL_VERSION}
