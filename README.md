# autoExpandLvmPartition

The script check the new increased existing disk size or new disks for device on /dev/sda, /dev/sdb/ and /dev/sdc.

Automatically the script does:

- Detects root Logical Volume name and Volume Group name
- Create the relative partition with fdisk command on the corrent dev/sdX
- Create phisical volume from dev/sdX
- Expand Volume group and extend Logical Volume
- Does xfs_growfs on root partition
