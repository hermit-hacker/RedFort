#!/bin/bash
#  
#  Software: RedFort
#  Author: Brian "Hermit" Mork
#  Version: 0.8.0
#  Modified: 2013-07-08
#
##########################################################################

#checkForHostOS
OSNAME="RHEL"
OSVER="6"
OSARCH="64"

# Determine where the script is being run from
SOURCE=$0
while [ -h "$SOURCE" ];
  do SOURCE="$(readlink "$SOURCE")"
done
RFDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Include helper functions
for FILE in `find $RFDIR/includes -wholename $RFDIR/includes/commands -prune -o -type f -print`; do
  . $FILE
done

# Setup globals and handlers
VERSION="0.8.0"
setGlobalValues
setLocations
buildModuleList
trap bashtrap INT

# Handle command line arguments
RUNANDSKIPCHECK="FALSE"
for ARGUMENT in $*; do
  TESTARG=`echo $ARGUMENT | cut -d "=" -f 1`
  ARGVAL=`echo $ARGUMENT | cut -d "=" -f 2`
  if [[ "$TESTARG" == "--runmodules" || "$TESTARG" == "--skipmodules" ]]; then
    if [ "$RUNANDSKIPCHECK" == "TRUE" ]; then
      echo "The --runmodules and --skipmodules options are exclusive.  Please"
      echo "just specify one or the other."
      exit 1
    else
      if [ "$TESTARG" == "--runmodules" ]; then
        RUNANDSKIPCHECK="RUN"
      else
        RUNANDSKIPCHECK="SKIP"
      fi
    fi
  fi
  parseParameter $TESTARG $ARGVAL
done

loadAllModules
removeExtraneousModules $RUNTYPE

# Begin actual execution
printFancyBanner
writeLogHeader
confirmHardening $RUNORSHOW
runFixes $RUNTYPE

# Cleanup
cleanFiles
cleanLogFile
readOnlyRoot $BCKUPLOC
closeoutRF
