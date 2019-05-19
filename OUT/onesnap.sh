#!/bin/bash

#echo -----------------------------------------------------------------------------------------
#echo Welcome to the snapshot processing script!
#echo Please set the simulation and analysis directories before beginning.
#echo Please also make sure that lowres.c and highres.c point to the correct simulation directory
#echo
#echo "USE: ./auto.sh SNAP HALO LL4 LL1"
#echo "    SNAP is the snapshot number"
#echo "    HALO is the number of halos to be analysed (largest first)"
#echo "	   LL4 is the linking length of the entire lowres snapshot"
#echo "    LL1 is the linking length for the smaller highres cutouts"
#echo -----------------------------------------------------------------------------------------
#echo

# directory containing the processing scripts
SCRIPTS=/home/rgudapati/Documents/Scripts

# directory containing the simulation snapshot
SIM=/home/rgudapati/Documents/512_M025S09_v1

# directory containing TIPSY
TIPSY=/home/rgudapati/tipsy/code

# directory containing FOF 
FOF=/home/rgudapati/fof-1.1

# directory in which to save output for this snapshot
OUT=/home/rgudapati/Documents/auto

# directory in which to save halos
HALOS=/home/rgudapati/Documents/auto/HALOS

# number of snapshot to be processed
SNAP=$1

# number of halos to analyse (the largest N halos will be included)
NUMHALO=$2

# linking length (skip 4 / lowres)
LL4=$3

# linking length (no skip / highres)
LL1=$4

echo " !!!		PROCESSING SNAPSHOT ${SNAP}		!!!"
echo

sed -i "/snapshot_number = /c\  snapshot_number = ${SNAP};" $SCRIPTS/lowres.c
sed -i "/snapshot_number = /c\  snapshot_number = ${SNAP};" $SCRIPTS/highres.c

# produce a skip-4 TIPSY format ascii file
echo "producing a lowres TIPSY ascii with skip size 4"
cd $SCRIPTS
sed -i "/tipsy();/c\  tipsy();" $SCRIPTS/lowres.c
gcc -w -o lowres lowres.c -lm
./lowres > $TIPSY/snap${SNAP}.ascii
echo "done."
echo

# produce a skip-4 TIPSY format bin file
echo "producing a TIPSY bin with skip size 4"
#echo "Please enter the appropriate commands to TIPSY for snap${SNAP}.ascii:"
#echo
cd $TIPSY
#echo -ne '\007'
echo "openascii snap${SNAP}.ascii
oldreadascii snap${SNAP}.bin nosph
closebinary
quit" | ./tipsy

# THESE COMMANDS MUST BE PASSED TO TIPSY MANUALLY
# openascii snap${SNAP}.ascii
# oldreadascii snap${SNAP}.bin nosph
# closebinary
# quit
#echo
echo "done."
echo
rm snap${SNAP}.ascii
mv snap${SNAP}.bin $FOF/snap${SNAP}.bin

# produce an FOF group file
echo "running FOF for the full snapshot with linking length $LL4"
cd $FOF
./fof -e $LL4 -o snap${SNAP} < snap${SNAP}.bin
echo "done."
echo
rm snap${SNAP}.bin
mv snap${SNAP}.grp $OUT/snap${SNAP}.grp

# create skip-4 POSID file
echo "creating a lowres posidgrp file for the full simulation with skip size 4"
sed -i "/tipsy();/c\  //tipsy();" $SCRIPTS/lowres.c
sed -i "/positions();/c\  positions();" $SCRIPTS/lowres.c

cd $SCRIPTS
gcc -w -o lowres lowres.c -lm
./lowres > $OUT/snap${SNAP}.pos

sed -i "/positions();/c\ //positions();" $SCRIPTS/lowres.c

cd $OUT
sed '1d' snap${SNAP}.grp > tmp; mv tmp snap${SNAP}.grp
paste -d' ' snap${SNAP}.pos snap${SNAP}.grp > snap${SNAP}.posgrp
rm snap${SNAP}.pos
echo "done."
echo

mkdir SNAP${SNAP}
mv snap${SNAP}.posgrp ./SNAP${SNAP}/snap${SNAP}.posgrp
mv snap${SNAP}.grp ./SNAP${SNAP}/snap${SNAP}.grp

cd SNAP${SNAP}
echo "creating a lowres idpos file for $NUMHALO halo(s) with skip size 4"
grep -v -e "^0$" snap${SNAP}.grp > t1.txt
sort t1.txt | uniq -c | sort -nr > t2.txt
awk '{print $2}' t2.txt > t3.txt 
head -n $NUMHALO t3.txt > snap${SNAP}.halos
rm t1.txt
rm t2.txt
rm t3.txt
#sort snap${SNAP}.grp | uniq -c | sort -n -r > t1
#awk '{print $2;}' t1 > t2
#head -n $(($NUMHALO+1)) t2 > snap${SNAP}.halos
#sed '1d' snap${SNAP}.halos > tmp; mv tmp snap${SNAP}.halos
# rm snap${SNAP}.grp
#rm t1
#rm t2
echo "done."
echo
#echo "creating idposgrp files for $NUMHALOS with no skip size"
#echo

echo "SUMMARY:" > $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt
echo >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt
echo

COUNT=1
while [ $COUNT -le $NUMHALO ]
do
	echo "creating highres idposgrp file for halo #$COUNT with no skip size"

	GRP=$( head -"$COUNT" snap${SNAP}.halos | tail -1 )
	awk '$4 ~'"/^${GRP}$/"'{$NF=""; print $0 }' snap${SNAP}.posgrp > $OUT/${COUNT}.pos
	
	LEN=$(wc -l < "$OUT/${COUNT}.pos")
	$SCRIPTS/properties $COUNT $LEN > temp.txt
	COM_X=$( awk '{print $1}' temp.txt )
	COM_Y=$( awk '{print $2}' temp.txt )
	COM_Z=$( awk '{print $3}' temp.txt )
	BSIZE=$( awk '{print $4}' temp.txt )

#	BT=$( awk '{print $4}' temp.txt )
#	BT="${BT//[$'\t\r\n ']}"
#	BT=$(($BSIZE+0))

	echo "$COM_X $COM_Y $COM_Z" > $HALOS/snap${SNAP}_halo${COUNT}.com

	echo "HALO $COUNT --> group $GRP (linking length $LL4):" >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt
	echo "COM = ($COM_X, $COM_Y, $COM_Z)" >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt
	echo "BOXSIZE = $BSIZE" >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt

	# TODO figure this out later

#	if [[ "$BT" -gt "146977" ]]
#	then 
#		echo "TOO MANY PARTICLES TO STORE!" >> $HALOS/snap${SNAP}_summary.txt
#		echo "Consider reducing the boxsize or increasing the skipsize" >> $HALOS/snap${SNAP}_summary.txt
#		echo >> $HALOS/snap${SNAP}_summary.txt
#		continue
#	fi

	rm temp.txt

	sed -i "/#define BOXSIZE/c\#define BOXSIZE ${BSIZE}" $SCRIPTS/highres.c
	sed -i "/#define COMX/c\#define COMX ${COM_X}" $SCRIPTS/highres.c
	sed -i "/#define COMY/c\#define COMY ${COM_Y}" $SCRIPTS/highres.c
	sed -i "/#define COMZ/c\#define COMZ ${COM_Z}" $SCRIPTS/highres.c

	sed -i "/posid();/c\ posid();" $SCRIPTS/highres.c
	gcc -w -o $SCRIPTS/highres $SCRIPTS/highres.c -lm

	$SCRIPTS/highres > $HALOS/snap${SNAP}_halo${COUNT}.idpos

	sed -i "/posid();/c\ //posid();" $SCRIPTS/highres.c
	sed -i "/tipsy();/c\ tipsy();" $SCRIPTS/highres.c
	gcc -w -o $SCRIPTS/highres $SCRIPTS/highres.c -lm
	$SCRIPTS/highres > $TIPSY/snap${SNAP}_halo${COUNT}.ascii
	sed -i "/tipsy();/c\ //tipsy();" $SCRIPTS/highres.c

	echo "done."
	echo

	echo "finding largest subhalo for halo #$COUNT"
	echo

	cd $TIPSY
	echo "please enter the tipsy commands for snap${SNAP}_halo${COUNT}.ascii"
	echo -ne '\007'
	echo "openascii snap${SNAP}_halo${COUNT}.ascii
	oldreadascii snap${SNAP}_halo${COUNT}.bin nosph
	closebinary
	quit" | ./tipsy
#	echo
	echo "done."
	echo
	rm snap${SNAP}_halo${COUNT}.ascii
	mv snap${SNAP}_halo${COUNT}.bin $FOF/snap${SNAP}_halo${COUNT}.bin

#	echo "creating FOF for highres using linking length $LL1"
	cd $FOF
	./fof -e $LL1 -o snap${SNAP}_halo${COUNT} < snap${SNAP}_halo${COUNT}.bin
#	echo "done."
#	echo
	rm snap${SNAP}_halo${COUNT}.bin
	mv snap${SNAP}_halo${COUNT}.grp $HALOS/snap${SNAP}_halo${COUNT}.grp
	
	cd $HALOS
	sed -i '1d' snap${SNAP}_halo${COUNT}.grp
	grep -v -e "^0$" snap${SNAP}_halo${COUNT}.grp > t1.txt
	sort t1.txt | uniq -c | sort -nr > t2.txt
	awk '{print $2}' t2.txt > t3
	rm t1.txt
	rm t2.txt
	SMHALO=$( head -n 1 t3 )
#	sort snap${SNAP}_halo${COUNT}.grp | uniq -c | sort -n -r > t1
#	awk '{print $2;}' t1 > t2
#	head -n 2 t2 > tt
#	awk '{ if ($1 > 0) print $0;}' tt > tt2
#	head -n 1 tt2 > tt
#	SMHALO=$( awk '{print $1;}' tt)
#	rm tt
#	rm tt2
	# rm snap${SNAP}.grp
#	rm t1
#	rm t2
#	rm t2.txt
	rm t3
#	echo "done."

#	echo "creating inner halo idpos file"
#	sed '1d' snap${SNAP}_halo${COUNT}.grp > tmp; mv tmp snap${SNAP}_halo${COUNT}.grp
	paste -d' ' snap${SNAP}_halo${COUNT}.idpos snap${SNAP}_halo${COUNT}.grp > snap${SNAP}_halo${COUNT}.idposgrp
	rm snap${SNAP}_halo${COUNT}.idpos
	awk '$5 ~'"/^${SMHALO}$/"'{$NF=""; print $0 }' snap${SNAP}_halo${COUNT}.idposgrp > $HALOS/snap${SNAP}_halo${COUNT}b.idpos
#	echo "done."
	echo
	
	BIGL=$( wc -l < $HALOS/snap${SNAP}_halo${COUNT}.idposgrp )
	echo "NUMBER OF PARTICLES = $BIGL" >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt

	# count number of subhalos
	grep -v -e "^0$" $HALOS/snap${SNAP}_halo${COUNT}.grp > t3
	sort t3 | uniq > $HALOS/snap${SNAP}_halo${COUNT}.grp
	NSM=$( wc -l < $HALOS/snap${SNAP}_halo${COUNT}.grp )
	PSM=$( wc -l < $HALOS/snap${SNAP}_halo${COUNT}b.idpos )
	rm t3

	echo "NUMBER OF SUBHALOES = $NSM" >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt
	echo "saved in $HALOS/snap${SNAP}_halo${COUNT}.idpos" >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt 
	echo "biggest subhalo has $PSM particles" >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt	
	echo >> $OUT/SNAP${SNAP}/snap${SNAP}_summary.txt

	rm $OUT/${COUNT}.pos
	rm $HALOS/snap${SNAP}_halo${COUNT}.grp
	cd $OUT/SNAP${SNAP}	
	((COUNT++))
done
#echo "done."
echo

echo "time to process snapshot $SNAP: $SECONDS seconds"
echo
