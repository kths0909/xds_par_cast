#!/bin/tcsh

###################################################################################
##                                                                               ##
##	xds_par (casted)                                                         ##
##                                                                               ##
##	Please change the normal "xds_par" to "xds_par_normal".                  ##
##                                                                               ##
##      (command) mv xds_par xds_par_normal                                      ##
##                                                                               ##
###################################################################################

set file_check="XDS.INP"

if ( -e ${file_check} ) then
##############################

set cluster_IP_address=hogehoge			##the IP address of your cluster machine.

set xdsinp_temp1=`mktemp`
set xdsinp_temp2=`mktemp`
set xdsinp_temp3=`mktemp`

cp XDS.INP XDS.INP_ORIGIN
cp XDS.INP ${xdsinp_temp2}
echo "\n">> ${xdsinp_temp2}

cat XDS.INP | awk 'BEGIN{FS="!"}{print $1}' > ${xdsinp_temp1}

set job_list=(`cat ${xdsinp_temp1} | awk '{if($0 ~ /JOB=/) printf $0}{printf " "}' | sed -e 's/\\t/ /g' -e 's/ +/ /g' -e 's/ JOB/JOB/' -e 's/= /=/' -e 's/ \$//' -e 's/ /=/g' -e 's/JOB=//' -e 's/=/ /g'`)
set cluster_node=`cat ${xdsinp_temp1} | awk '{if($0 ~ /CLUSTER_NODES=/) printf $0}{printf " "}' | sed -e 's/\\t//g' -e 's/ //g' -e 's/CLUSTER_NODES=//'`

if ( "${cluster_node}" == "" ) then
	set cluster_flag="False"
else
	set cluster_flag="True"
endif

#echo $cluster_flag				##DEBUG
#echo $cluster_node				##DEBUG
#echo $job_list					##DEBUG

set job_num=1
set job_max=$#job_list
set DIR_pwd=`pwd`

while ( $job_num <= $job_max )
#	echo $job_list[$job_num]		##DEBUG
#	echo $job_num				##DEBUG

	cat ${xdsinp_temp2} | awk -v "job_operate=$job_list[$job_num]" 'BEGIN{FS="!"}{if($1 ~ /JOB=/) print "!" $0}{if($1 ~ /JOB=/) print "JOB=" job_operate}{if($1 !~ /JOB=/) print $0}' > ${xdsinp_temp3}

	switch ( $job_list[$job_num] )
	case XYCORR:
	case INIT:
	case IDXREF:
	case DEFPIX:
	case XPLAN:
	case CORRECT:
		if ( $cluster_flag == "True" ) then
			cat ${xdsinp_temp3} | awk 'BEGIN{FS="!"}{if($1 ~ /MAXIMUM_NUMBER_OF_JOBS=/) print "!" $0}{if($1 !~ /MAXIMUM_NUMBER_OF_JOBS=/) print $0}' | awk 'BEGIN{FS="!"}{if($1 ~ /MAXIMUM_NUMBER_OF_PROCESSORS=/) print "!" $0}{if($1 !~ /MAXIMUM_NUMBER_OF_PROCESSORS=/) print $0}' | awk 'BEGIN{FS="!"}{if($1 ~ /CLUSTER_NODES=/) print "!" $0}{if($1 !~ /CLUSTER_NODES=/) print $0}' | tee XDS.INP_$job_list[$job_num] XDS.INP > /dev/null
#			echo $job_list[$job_num]"_cluster"	##DEBUG
		else
			cp ${xdsinp_temp3} XDS.INP_$job_list[$job_num]
			cp ${xdsinp_temp3} XDS.INP
#			echo $job_list[$job_num]"_single"	##DEBUG
		endif

#		echo $job_list[$job_num]			##DEBUG
		xds_par_normal
		breaksw
	case COLSPOT:
	case INTEGRATE:
		cp ${xdsinp_temp3} XDS.INP_$job_list[$job_num]
		cp ${xdsinp_temp3} XDS.INP

		if ( $cluster_flag == "True" ) then
#			echo $job_list[$job_num]_par		##DEBUG	
			ssh $cluster_IP_address "cd $DIR_pwd ;xds_par"
		else
#			echo $job_list[$job_num]_normal		##DEBUG
			xds_par_normal
		endif
			


		breaksw
	default:
		breaksw
	endsw	

	@ job_num++
end


cp ${xdsinp_temp2} XDS.INP

##############################
else
	echo "There is no XDS.INP"
endif 




