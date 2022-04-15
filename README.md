# autoExpandLvmPartition

The script check the new increased existing disk size or new disks for device on /dev/sda, /dev/sdb/ and /dev/sdc.

Supports until 15 x 4 partitions that is the VMware limit of new disks (15 devices) per virtual SCSI adapter of a Virtual Machine

Automatically the script does:

- Detects root Logical Volume name and Volume Group name
- Create the relative LVM partition with fdisk command on the corrent dev/sdX
- Create phisical volume from dev/sdX
- Expands Volume group and extend Logical Volume
- Does xfs_growfs on root partition
