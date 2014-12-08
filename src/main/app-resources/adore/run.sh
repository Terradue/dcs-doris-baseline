#!/bin/bash
 
# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_MASTER=10
ERR_SLAVE=20
ERR_EXTRACT=30
ERR_ADORE=40
ERR_PUBLISH=50

# add a trap to exit gracefully
function cleanExit ()
{
  local retval=$?
  local msg=""
	
  case "$retval" in
		$SUCCESS) msg="Processing successfully concluded";;
		$ERR_MASTER) msg="Failed to retrieve the master product";;
     $ERR_SLAVE) msg="Failed to retrieve the slave product";;
$ERR_EXTRACT) msg="Failed to retrieve the extract the vol and lea";;
		$ERR_ADORE) msg="Failed during ADORE execution";;
		$ERR_PUBLISH) msg="Failed results publish";;
		*) msg="Unknown error";;
  esac

  [ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
  rm -rf $TMPDIR	
  exit $retval
}
trap cleanExit EXIT

# shorter temp path 
TMPDIR="/tmp/`uuidgen`"

# creates the adore directory structure
ciop-log "INFO" "creating the directory structure"
mkdir -p $TMPDIR/input

master_ref="`ciop-getparam master`"

master="`echo $master_ref | ciop-copy -O $TMPDIR/input -`"
[ $? -ne 0 ] && exit $ERR_MASTER

mabsorb=`basename $master | awk 'BEGIN { FS="_" } { print $7 }'`
mkdir -p $TMPDIR/run/data/$mabsorb

ln -s $master $TMPDIR/run/data/$mabsorb/`basename $master`


while read slave_ref
do

  ciop-log "INFO" "Retrieving slave"
  slave="`echo $slave_ref | ciop-copy -U -O $TMPDIR -`"
  [ $? -ne 0 ] && exit $ERR_SLAVE

  sabsorb=`basename $sabsorb | awk 'BEGIN { FS="_" } { print $7 }'`
  mkdir -p $TMPDIR/run/data/$sabsorb

  ln -s $slave $TMPDIR/run/data/$sabsorb/`basename $slave`

done

ciop-log "INFO" "Launching adore for baseline"
export ADORESCR=/opt/adore/scr
export PATH=/usr/local/bin:/opt/adore/scr:$PATH
adore "p $_CIOP_APPLICATION_PATH/adore/libexec/baseline.adr $mabsorb $TMPDIR/run/data"

[ $? -ne 0 ] && exit $ERR_ADORE

ciop-publish -m $TMPDIR/run/process/*.eps
res=$?

[ $res -ne 0 ] && exit $ERR_PUBLISH
 
rm -rf $TMPDIR

ciop-log "INFO" "Done"
