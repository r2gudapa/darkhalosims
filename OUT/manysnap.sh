#!/bin/bash

echo
echo "***********************************************************************************************"
echo "To use: ./manysnap.sh BEG END HALOS LL4 LL1"
echo
echo "	where BEG is the number of the first snapshot to be processed and END is the last"
echo "	HALOS is the number of halos to be produced by each snapshot"
echo "	LL4 is the linking length for the full snapshot, LL1 is for the cutouts"
echo "***********************************************************************************************"
echo

BEG=$1
END=$2
HALOS=$3
LL4=$4
LL1=$5

# stores auxiliary files created by merge.sh
# HALODIR=/home/rgudapati/Documents/auto/HALOS

# directory containing merge.sh onesnap.sh and manysnap.sh 
#     also where evol.merge will be placed
# OUT=/home/rgudapati/Documents/auto

COUNTER=$1

while [ $COUNTER -le $END ]
do
	./onesnap.sh $COUNTER $HALOS $LL4 $LL1
	((COUNTER++))
done

#cd $HALODIR
echo "!!!   Now running merge.sh   !!!"
echo
./merge.sh $BEG $END $HALOS
rm *.idgrp

echo "time to process all snapshots: $SECONDS seconds"
