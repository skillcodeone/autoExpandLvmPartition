#!/bin/bash
#rescan increased existing disk size or new disk
printf "Scanning for increased existing disk size or new disks...\n"
echo "- - -" > /sys/class/scsi_host/host0/scan;
echo "- - -" > /sys/class/scsi_host/host1/scan;
echo "- - -" > /sys/class/scsi_host/host2/scan;

#sda
DIR_SDA="/sys/block/sda"
if [ -d "$DIR_SDA" ]; then
  partprobe /dev/sda 2> /dev/null;
        partx -u /dev/sda 2> /dev/null;
        echo 1 > /sys/class/block/sda/device/rescan;
fi
#sdb
DIR_SDB="/sys/block/sdb"
if [ -d "$DIR_SDB" ]; then
  partprobe /dev/sdb 2> /dev/null;
        partx -u /dev/sdb 2> /dev/null;
        echo 1 > /sys/class/block/sdb/device/rescan;
fi
#sdc
DIR_SDC="/sys/block/sdc"
if [ -d "$DIR_SDC" ]; then
  partprobe /dev/sdc 2> /dev/null;
        partx -u /dev/sdc 2> /dev/null;
        echo 1 > /sys/class/block/sdc/device/rescan;
fi

#retrive data about sda partitions
LAST_SDA=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sda | awk '{ print $1}' |  sed s/sda// | sed -n '$p'`
SDA=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sda | awk '{ print $2}' | sed s/G// | sed -n '1p'`
SDA1=`lsblk /dev/sda1 -l --output NAME,SIZE 2> /dev/null | grep sda | awk '{ print $2}' | sed s/G//`
SDA2=`lsblk /dev/sda2 -l --output NAME,SIZE 2> /dev/null | grep sda | awk '{ print $2}' | sed s/G//`
SDA3=`lsblk /dev/sda3 -l --output NAME,SIZE 2> /dev/null | grep sda | awk '{ print $2}' | sed s/G//`
SDA4=`lsblk /dev/sda4 -l --output NAME,SIZE 2> /dev/null | grep sda | awk '{ print $2}' | sed s/G//`

#retrive data about sdb partitions
LAST_SDB=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sdb | awk '{ print $1}' |  sed s/sdb// | sed -n '$p'`
SDB=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sdb | awk '{ print $2}' | sed s/G// | sed -n '1p'`
SDB1=`lsblk /dev/sdb1 -l --output NAME,SIZE 2> /dev/null | grep sdb | awk '{ print $2}' | sed s/G//`
SDB2=`lsblk /dev/sdb2 -l --output NAME,SIZE 2> /dev/null | grep sdb | awk '{ print $2}' | sed s/G//`
SDB3=`lsblk /dev/sdb3 -l --output NAME,SIZE 2> /dev/null | grep sdb | awk '{ print $2}' | sed s/G//`
SDB4=`lsblk /dev/sdb4 -l --output NAME,SIZE 2> /dev/null | grep sdb | awk '{ print $2}' | sed s/G//`

#retrive data about sdc partitions
LAST_SDC=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sdc | awk '{ print $1}' |  sed s/sdc// | sed -n '$p'`
SDC=`lsblk -l --output NAME,SIZE 2> /dev/null | grep sdc | awk '{ print $2}' | sed s/G// | sed -n '1p'`
SDC1=`lsblk /dev/sdc1 -l --output NAME,SIZE 2> /dev/null | grep sdc | awk '{ print $2}' | sed s/G//`
SDC2=`lsblk /dev/sdc2 -l --output NAME,SIZE 2> /dev/null | grep sdc | awk '{ print $2}' | sed s/G//`
SDC3=`lsblk /dev/sdc3 -l --output NAME,SIZE 2> /dev/null | grep sdc | awk '{ print $2}' | sed s/G//`
SDC4=`lsblk /dev/sdc4 -l --output NAME,SIZE 2> /dev/null | grep sdc | awk '{ print $2}' | sed s/G//`

#retrive volume group and logical volume
VG=`lvs | grep root | awk {'print$2'}`
LV=`lvs | grep root | awk {'print$1'}`

#convert string to num
#sda
NEW_SDA=$(($LAST_SDA+1))
TOT_SDA=$(($SDA+0))
SUM_SDA=$(($SDA1+$SDA2+$SDA3+$SDA4+0))
#sdb
NEW_SDB=$(($LAST_SDB+1))
TOT_SDB=$(($SDB+0))
SUM_SDB=$(($SDB1+$SDB2+$SDB3+$SDB4+0))
#sdc
NEW_SDC=$(($LAST_SDC+1))
TOT_SDC=$(($SDC+0))
SUM_SDC=$(($SDC1+$SDC2+$SDC3+$SDC4+0))

#check sda sum partition
if [[ -z "$SUM_SDA" ]] && [[ -z "$TOT_SDA" ]]; then
  echo "Error retriving sda partition";
  exit 1;
fi

#check sda sum partition
if [[ -z "$SUM_SDB" ]] && [[ -z "$TOT_SDB" ]]; then
  echo "Error retriving sda partition";
  exit 1;
fi

#check sda sum partition
if [[ -z "$SUM_SDC" ]] && [[ -z "$TOT_SDC" ]]; then
  echo "Error retriving sda partition";
  exit 1;
fi

# for sda
if [ "$TOT_SDA" -eq "$SUM_SDA" ]; then
        echo "Expand LVM partition not necesssary for sda";
else
        CMD1SDA=`printf "n\np\n${NEW_SDA}\n\n\nt\n${NEW_SDA}\n8e\n\nw" | fdisk /dev/sda`;
        echo "Trying to create a new partition sda"$NEW_SDA"...";
        CMD2SDA=`partprobe /dev/sda`;
        CMD3SDA=`pvcreate /dev/sda"$NEW_SDA"`;
        if [ $? -eq 0 ]; then
                echo "Creating phisical volume sda"$NEW_SDA"...";
                CMD4SDA=`vgextend "$VG" /dev/sda"$NEW_SDA"`;
                CMD5SDA=`lvextend -l+100%FREE /dev/mapper/"$VG"-"$LV"`;
                CMD6SDA=`xfs_growfs /dev/mapper/"$VG"-"$LV"`;
                echo "Extending logical volume "$LV"...";
  else
                echo "Error, can't create new partition sda"$NEW_SDA"...";
                exit 1;
  fi
fi

#main for sdb
if [ "$TOT_SDB" -eq "$SUM_SDB" ]; then
        echo "Expand LVM partition not necesssary for sdb";
else
        echo "Trying to create a new partition sdb"$NEW_SDB"...";
                if [ $NEW_SDB -eq "1" ]; then
                        CMD1SDB=`printf "n\np\n${NEW_SDB}\n\n\nt\n8e\n\nw" | fdisk /dev/sdb`;
                else
                        CMD1SDB=`printf "n\np\n${NEW_SDB}\n\n\nt\n${NEW_SDB}\n8e\n\nw" | fdisk /dev/sdb`;
                fi
        CMD2SDB=`partprobe /dev/sdb`;
        CMD3SDB=`pvcreate /dev/sdb"$NEW_SDB"`;
        if [ $? -eq 0 ]; then
                echo "Creating phisical volume sdb"$NEW_SDB"...";
                CMD4SDB=`vgextend "$VG" /dev/sdb"$NEW_SDB"`;
                CMD5SDB=`lvextend -l+100%FREE /dev/mapper/"$VG"-"$LV"`;
                CMD6SDB=`xfs_growfs /dev/mapper/"$VG"-"$LV"`;
                echo "Extending logical volume "$LV"...";
  else
                echo "Error, can't create new partition sdb"$NEW_SDB"...";
                exit 1;
  fi
fi

#main for sdc
if [ "$TOT_SDC" -eq "$SUM_SDC" ]; then
        echo "Expand LVM partition not necesssary for sdc";
else
        echo "Trying to create a new partition sdb"$NEW_SDB"...";
                if [ $NEW_SDC -eq "1" ]; then
                        CMD1SDB=`printf "n\np\n${NEW_SDC}\n\n\nt\n8e\n\nw" | fdisk /dev/sdc`;
                else
                        CMD1SDB=`printf "n\np\n${NEW_SDC}\n\n\nt\n${NEW_SDC}\n8e\n\nw" | fdisk /dev/sdc`;
                fi
        CMD2SDC=`partprobe /dev/sdc`;
        CMD3SDC=`pvcreate /dev/sdc"$NEW_SDC"`;
        if [ $? -eq 0 ]; then
                echo "Creating phisical volume sdc"$NEW_SDC"...";
                CMD4SDC=`vgextend "$VG" /dev/sdc"$NEW_SDC"`;
                CMD5SDC=`lvextend -l+100%FREE /dev/mapper/"$VG"-"$LV"`;
                CMD6SDC=`xfs_growfs /dev/mapper/"$VG"-"$LV"`;
                echo "Extending logical volume "$LV"...";
  else
                echo "Error, can't create new partition sdc"$NEW_SDC"...";
                exit 1;
  fi
fi
