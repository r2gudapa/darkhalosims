#!/bin/bash

#echo
#echo "to use: ./merge BEG END NH"
#echo "where NH is the number of halos to process for mergers"
#echo

SCRIPTS=/home/rgudapati/Documents/Scripts

BEG=$1
END=$2
NH=$3

SNAP=$2

echo "creating full idgrp files"
while [ "$SNAP" -ge "$BEG" ]
do 
	I=1
	while [ "$I" -le "$NH" ]
	do
		awk '{ print $1 " " $5 }' snap${SNAP}_halo${I}.idposgrp > snap${SNAP}_halo${I}a.idgrp
		((I++))
	done

	echo > snap${SNAP}.merge

((SNAP--))
done
echo "done"
echo

SNAP=$2
I=1

echo > evol.merge

while [ $I -le "$NH" ]
do
	CNEXT=0 # cutout in which previous step's progenitor is found
	NEXT=0 # group number of previous step's progenitor wrt the correct cutout
	SNAP=$2
	while [ $SNAP -gt "$BEG" ]
	do
		if [[ "$SNAP" -le "$BEG" ]]
		then
			break
		elif [[ "$SNAP" -eq "$END" ]] 
		then
			CNEXT=0
			NEXT=0
			K=$I
			
			# search for largest halo in cutout
			awk '{ print $5 }' snap${SNAP}_halo${I}.idposgrp > t1
			sort t1 | uniq -c | sort -nr > t2
			awk '{ print $2 }' t2 > t1
			grep -v -e "^0$" t1 > t2

			# set largest halo in cutout
			LSUB=$( head -n 1 t2 ) 
			rm t1
			rm t2

			echo "------ START: SNAPSHOT $SNAP CUTOUT $I HALO $LSUB -------"	
			# list id and group number of particles in largest halo 
			awk -v lsub="$LSUB" '{ if ($5 == lsub) print $1 " " $5; }' snap${SNAP}_halo${I}.idposgrp > snap${SNAP}_halo${I}b.idgrp

		elif [ "$CNEXT" -eq 0 ]
		then 
			# there was no progenitor in the previous step
			break
		else	
			# the halo who's cutout needs to be found is called the HOI (halo of interest)
			
			# the cutout in which HOI resides
			K="$CNEXT"

			# the group number of the HOI
			LSUB="$NEXT"

			# print ids and group number of all particles in HOI
			awk -v lsub="$LSUB" '{ if ($5 == lsub) print $1 " " $5; }' snap${SNAP}_halo${K}.idposgrp > snap${SNAP}_halo${K}b.idgrp
		fi
	
		# snapshot in which HOI is located
		SC=$SNAP

		# snapshot in which we are looking for the progenitor of HOI
		((SNAP--))
		
		if [[ "$SC" -eq "$END" ]]
		then 
			sed -i "/snapshot_number = /c\ snapshot_number = ${SC};" $SCRIPTS/highres.c
			sed -i "/redshift();/c\ redshift();" $SCRIPTS/highres.c
			gcc -w -o $SCRIPTS/highres $SCRIPTS/highres.c -lm
			redshift=$( $SCRIPTS/highres )
			mass=$( wc -l < snap${SC}_halo${I}b.idgrp )
			echo "${SC}" "${K}" "${LSUB}" "$mass" "$redshift" >> evol.merge
			sed -i "/redshift();/c\ //redshift();" $SCRIPTS/highres.c
		fi

		biggest=0
		numbg=0
		cutbg=0
		
		# decide which cutout to search in 

		# find center of mass of HOI
		# initialize min distance with FLT_MAX

		# loop over all j cutouts
			# subtract com (HOI, SC) - com (j, SNAP) for each of the three directions
			# add differences in quad
			# set new minimum distance if applicable (var $J)
			# set cutout number with minimum distance if applicable
			# move to next cutout
			
		COM_HX=$( awk '{print $1}' snap${SC}_halo${K}.com )
		COM_HY=$( awk '{print $2}' snap${SC}_halo${K}.com )
		COM_HZ=$( awk '{print $3}' snap${SC}_halo${K}.com )

		MIN_D=0
		F=1
		J=0
		while [ $F -le "$NH" ]
		do
			COMX=$( awk '{print $1}' snap${SNAP}_halo${F}.com )
			COMY=$( awk '{print $2}' snap${SNAP}_halo${F}.com )
			COMZ=$( awk '{print $3}' snap${SNAP}_halo${F}.com )

			DIS_X=$( bc <<< "$COM_HX - $COMX" )
			DIS_Y=$( bc <<< "$COM_HY - $COMY" )
			DIS_Z=$( bc <<< "$COM_HZ - $COMZ" )

			SQRX=$( bc <<< "$DIS_X * $DIS_X" )
			SQRY=$( bc <<< "$DIS_Y * $DIS_Y" )
			SQRZ=$( bc <<< "$DIS_Z * $DIS_Z" )

			ADD=$( bc <<< "$SQRX + $SQRY + $SQRZ" )

			DIST=$( bc <<< "sqrt(${ADD})" )

			#echo "COM search cutout $F: DIST = $DIST | MIN_D = $MIN_D"
			if [ $F -eq 1 ]
			then
				MIN_D=$DIST
				J=$F
			elif (( $(echo "$DIST < $MIN_D" |bc -l) ))
			then 
				MIN_D=$DIST
				J=$F
			fi
			((F++))
		done #found cutout
		
		echo 	
		echo "searching: SNAP${SNAP} CUTOUT $J for largest progenitor of $SC:$K:$LSUB"
		join -1 1 -2 1 -o 2.2 <(sort -nk 1b,1 snap"${SC}"_halo"${K}"b.idgrp) <(sort -nk 1b,1 snap"${SNAP}"_halo${J}a.idgrp) > t1
		sort t1 | uniq -c | sort -nr > t2
		awk '{ print $2 }' t2 > groups
		awk '{ print $1 }' t2 > num_migrated
		rm t1
		rm t2

		GRP=1
		while [ $GRP -le "$NH" ] # loop over groups
		do
			grpnum=$( head -"$GRP" groups | tail -1 )
			
			if [ "$grpnum" -eq 0 ]
			then
				((GRP++))
				continue
			fi
			
			awk -v group="$grpnum" '{ if ($2 == group) print $0; }' snap${SNAP}_halo${J}a.idgrp > snap${SNAP}_halo${J}b.idgrp
			PARTS=$( wc -l < snap${SNAP}_halo${J}b.idgrp )
			HALF=$(( PARTS / 2 ))
			MIG=$( head -"$GRP" num_migrated | tail -1 )

			if [ "$MIG" -ge "$HALF" ]
			then
				if [ "$PARTS" -gt "$numbg" ]
				then
					biggest="$grpnum"
					numbg="$PARTS"
					cutbg="$J"
				else
					((GRP++))
					continue
				fi
			else
				((GRP++))
				continue
			fi
			((GRP++))
		done # loop over groups
		((J++))
		echo
				
		if [ "$numbg" -eq 0 ] # no progenitor found
		then
			echo "END" >> evol.merge
			echo >> evol.merge
			echo "   no progenitor found :("
			echo
			rm groups
			rm num_migrated
			NEXT=0
			CNEXT=0
			break
		else
			awk -v grp="$biggest" '{ if ($2 == grp) print $0; }' snap${SNAP}_halo${cutbg}a.idgrp > temp
			mass=$( wc -l < temp )

			sed -i "/redshift();/c\ redshift();" $SCRIPTS/highres.c
			sed -i "/snapshot_number = /c\ snapshot_number = ${SNAP};" $SCRIPTS/highres.c
			gcc -w -o $SCRIPTS/highres $SCRIPTS/highres.c -lm
			redshift=$( $SCRIPTS/highres )
			echo "${SNAP} $cutbg $biggest $mass" > snap${SC}.merge
			awk -v red="$redshift" '{ print $0 " " red}' snap${SC}.merge >> evol.merge
			if [ "$SNAP" -eq "$BEG" ]
			then
				echo >> evol.merge
			fi
			sed -i "/redshift();/c\ //redshift();" $SCRIPTS/highres.c
			
			echo "   progenitor found! $SNAP:$cutbg:$biggest"
			echo
			rm groups
			rm num_migrated
			NEXT="$biggest"
			CNEXT="$cutbg"
			rm temp
		fi
	done # found all progenitors
	
	SNAP=$END

	#while [ $SNAP -gt "$BEG" ]
	#do
	#	NSH=$SNAP
	#	((SNAP--))
	#done

	if [[ "$I" -ge "$NH" ]]
	then
		echo
		echo "Goodbye!"
		echo "time elapsed: $SECONDS seconds"
		echo
		break
	fi
	((I++))
done


echo "removing full idgrp files"
while [ "$SNAP" -ge "$BEG" ]
do 
	I=1
	while [ "$I" -le "$NH" ]
	do
		rm snap${SNAP}_halo${I}a.idgrp
		((I++))
	done

((SNAP--))
done
echo "done"
echo

 rm snap*.merge
 rm *.idgrp
 rm *.id
 rm *.idpos

# keep .com and .idposgrp files if you want to run merge without running the entire program again 
#		this will require more space
# rm *.com
# rm *.idposgrp

ALLSNAPS=$((END-BEG+1))

awk '{ print $1 }' evol.merge > snapshots
awk '{ print $2 }' evol.merge > cutouts
awk '{ print $3 }' evol.merge > halos


COUNT=1
LINES=$((ALLSNAPS*NH+NH+1))

echo > nfwparams

while [ $COUNT -le "$LINES" ]
do
	fone=$( head -"$COUNT" snapshots | tail -1 )
	cut=$( head -"$COUNT" cutouts | tail -1 )
	grp=$( head -"$COUNT" halos | tail -1 )

	if [[ "$fone" == "END" ]]
	then 
		echo >> nfwparams
		((COUNT++))

	elif [[ "$fone" == "" ]]
	then 
		echo >> nfwparams
		((COUNT++))
	else
		echo $fone $cut $grp

		awk -v group="$grp" '{if ($5 == group) print $2 " " $3 " " $4;}' snap${fone}_halo${cut}.idposgrp > ${fone}_${cut}_${grp}.pos
		
		python $SCRIPTS/nfw.py "${fone}_${cut}_${grp}" "${fone}" "${cut}"
		((COUNT++))
	fi
done

sed -i '1d' nfwparams
rm *.pos

cp evol.merge progtree
paste -d' ' progtree nfwparams > evol.merge 
