#!/bin/bash
#rescan increased existing disk size or new disk
printf "Scanning for increased existing disk size or new disks...\n"
echo "- - -" > /sys/class/scsi_host/host0/scan;
echo "- - -" > /sys/class/scsi_host/host1/scan;
echo "- - -" > /sys/class/scsi_host/host2/scan;

device_letter=("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" )

#retrive volume group and logical volume
VG=`lvs | grep root | awk {'print$2'}`
LV=`lvs | grep root | awk {'print$1'}`

function expandLvm ()
{
DEV="${1}"
#rescan device
DEV_PATH="/sys/block/sd"$DEV
if [ -d "$DEV_PATH" ]; then
  partprobe /dev/sd$DEV 2> /dev/null;
  partx -u /dev/sd$DEV 2> /dev/null;
  echo 1 > /sys/class/block/sd$DEV/device/rescan;
fi

#retrive data about sdX partitions
LAST_DEV=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sd"$DEV" | awk '{ print $1}' |  sed s/sd"$DEV"// | sed -n '$p'`
DEVX=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sd"$DEV" | awk '{ print $2}' | sed s/G// | sed -n '1p'`
DEV1=`lsblk /dev/sd"$DEV"1 -l --output NAME,SIZE 2> /dev/null | grep sd"$DEV" | awk '{ print $2}' | sed s/G//`
DEV2=`lsblk /dev/sd"$DEV"2 -l --output NAME,SIZE 2> /dev/null | grep sd"$DEV" | awk '{ print $2}' | sed s/G//`
DEV3=`lsblk /dev/sd"$DEV"3 -l --output NAME,SIZE 2> /dev/null | grep sd"$DEV" | awk '{ print $2}' | sed s/G//`
DEV4=`lsblk /dev/sd"$DEV"4 -l --output NAME,SIZE 2> /dev/null | grep sd"$DEV" | awk '{ print $2}' | sed s/G//`

#sdX
NEW_DEV=$(($LAST_DEV+1))
TOT_DEV=$(($DEVX+0))
SUM_DEV=$(($DEV1+$DEV2+$DEV3+$DEV4+0))

#check sdX sum partition
if [[ -z "$SUM_DEV" ]] && [[ -z "$TOT_DEV" ]]; then
  echo "Error retriving sd"$DEV" partition";
  exit 1;
fi


#main for sdX
if [ "$TOT_DEV" -eq "$SUM_DEV" ]; then
        echo "Expand LVM partition not necesssary for sd"$DEV;
else
        echo "Trying to create a new partition sd"$DEV$NEW_DEV"...";
                if [ $NEW_DEV -eq "1" ]; then
                        CMD1=`printf "n\np\n${NEW_DEV}\n\n\nt\n8e\n\nw" | fdisk /dev/sd$DEV`;
                else
                        CMD1=`printf "n\np\n${NEW_DEV}\n\n\nt\n${NEW_DEV}\n8e\n\nw" | fdisk /dev/sd$DEV`;
                fi
        CMD2=`partprobe /dev/sd"$DEV"`;
        CMD3=`pvcreate /dev/sd"$DEV$NEW_DEV"`;
        if [ $? -eq 0 ]; then
                echo "Creating phisical volume sd"$DEV$NEW_DEV"...";
                CMD4=`vgextend "$VG" /dev/sd"$DEV$NEW_DEV"`;
                CMD5=`lvextend -l+100%FREE /dev/mapper/"$VG"-"$LV"`;
                CMD6=`xfs_growfs /dev/mapper/"$VG"-"$LV"`;
                echo "Extending logical volume "$LV"...";
  else
                echo "Error, can't create new partition sd"$DEV$NEW_DEV"...";
                exit 1;
  fi
fi
}

for i in ${!device_letter[@]}; do
  expandLvm ${device_letter[$i]}
done
