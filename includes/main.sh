#!/bin/bash
#  
#  Software: RedFort
#  Module: RF Main Helper Functions
#  Author: Brian "Hermit" Mork
#  Version: 0.8.0 
#  Modified: 2013-07-08
#
##########################################################################

##########################################################################
# Write an entry to the log
writeToLog()
{
  LOGTIME=`date | cut -c 12-19 | sed "s/\://g"`
  if [ "$1" = "line" ]; then
     echo "------------------------------------------------------------------------------" >> $LOGFILE
  elif [ "$1" = "modname" ]; then
     echo "$LOGTIME : ----- $2 -----" >> $LOGFILE
  else
     echo "$LOGTIME : $1" >> $LOGFILE
  fi
}


##########################################################################
# Check for a RHEL/CENTOS installation
checkForHostOS()
{
  # Get the OS name
  if [ ! -e /etc/redhat-release ]; then
    echo "ERROR: This is not a RHEL or CENTOS system."
    exit 71
  elif [ `grep -c CentOS /etc/redhat-release` -eq 0 ]; then
      OSNAME=`sed 's/Red Hat Enterprise Linux/RHEL/'`
      OSVER=`echo "$OSNAME" | cut -d " " -f 4 | cut -d "." -f 1`
    else
      OSNAME=`cat /etc/redhat-release`
      OSVER=`echo "$OSNAME" | cut -d " " -f 3 | cut -d "." -f 1`
  fi
  # Get the architecture
  if [ `uname -i | grep -c 64` -eq 0 ]; then
    OSARCH="32"
  else
    OSARCH="64"
  fi  
}


##########################################################################
# Capture CTRL+C and write to logfile
bashtrap()
{
  writeToLog "CTRL+C code break"
  echo
  echo "CTRL+C used to end run. The log file is located at:"
  echo "$LOGFILE"
  cleanFiles
  cleanLogFile
  exit 50
}


##########################################################################
# Make sure a user wants to actually harden the system
confirmHardening()
{
  if [[ "$RUNORSHOW" == "RUN"  &&  "$RUNTYPE" != "AUDIT" && "$RUNTYPE" != "RMODS" ]]; then
    ask "You are about to harden this system.  Do you want to continue?"
    if [ $RETVAL -eq 0 ]; then
      exit 0
    fi
  fi
}


##########################################################################
# Set module status to FAIL
setModuleFail()
{
  FAILFLAG="FAIL"
}


##########################################################################
# Output module heading to screen and log file
reportModuleRunning()
{
  echo "Running module: $1"
  FAILFLAG="PASS"
  writeToLog "Module: $1 Executing"
}


##########################################################################
# Output module completion to screen an log file
reportModuleComplete()
{
  STATDESC="Module complete: $1"
  declare -i WL=70
  declare -i STATDES=${#STATDESC}
  declare -i STATLEN=${#FAILFLAG}
  declare -i PAD=$WL-$STATLEN-$STATDES
  echo -n "$STATDESC"
  padPrint $PAD
  if [ "$FAILFLAG" != "FAIL" ]; then
    echo -e "[ \033[32m$STATUS\033[m ]"
  else
    echo -e "[ \033[31m$STATUS\033[m ]"
  fi
  echo
  writeToLog "Module: $1 completed with status: $FAILFLAG"
}


##########################################################################
# Update status for a task
reportTaskStatus()
{
  STATDESC=$1
  STATUS=$2
  STATCOL=$3
  declare -i WL=70
  declare -i STATDES=${#STATDESC}
  declare -i STATLEN=${#STATUS}
  declare -i PAD=$WL-$STATLEN-$STATDES
  echo -n "$STATDESC"
  padPrint $PAD
  if [ "$STATCOL" == "red" ]; then
    echo -e "[ \033[31m$STATUS\033[m ]"
  else
    echo -e "[ \033[32m$STATUS\033[m ]"
  fi
}


##########################################################################
# Update status for a sub task
reportSubTaskStatus()
{
  STATDESC="    + $1"
  STATUS=$2
  STATCOL=$3
  declare -i WL=70
  declare -i STATDES=${#STATDESC}
  declare -i STATLEN=${#STATUS}
  declare -i PAD=$WL-$STATLEN-$STATDES
  echo -n "$STATDESC"
  padPrint $PAD
  if [ "$STATCOL" == "red" ]; then
    echo -e "[ \033[31m$STATUS\033[m ]"
  else
    echo -e "[ \033[32m$STATUS\033[m ]"
  fi
}


##########################################################################
# Provide a status heading
reportStatusHeading()
{
  echo " [-] $1"
}


##########################################################################
# Execute selected fixes
##########################################################################
padPrint()
{
  declare -i TOTS=$1
  declare -i LOOPS=0
  while [ $LOOPS -lt $TOTS ]; do
    echo -n " "
    LOOPS=$LOOPS+1
  done
}

##########################################################################
# Execute selected fixes
##########################################################################
runFixes()
{
  RT=$1
  if [ "$RT" == "AUDIT" ]; then
    fileExists $CHECKLIST
    if [ "$ISFILE" == "yes" ]; then
      echo "Detected OS: $OSNAME version $OSVER"
      echo
      while read AUDLINE; do
        $AUDLINE
      done < $CHECKLIST
    fi
  else
    fileExists $FIXLIST
    if [ "$ISFILE" == "yes" ]; then
      echo "Detected OS: $OSNAME version $OSVER"
      echo
      while read FIXLINE; do
        FIXCOM=`echo $FIXLINE | cut -d " " -f 2`
        $FIXCOM $RUNTYPE
      done < $FIXLIST
    fi
  fi
}


##########################################################################
# Removes temporary/working files
##########################################################################
cleanFiles()
{
  for FILE in {$FIXLIST,$CHECKLIST,$MODLIST,$UNDOLIST,$UNDOMENUFILE,$UNDOSORTED,$ALLBACKUPS,$BACKUPMENU}; do
    clearFile $FILE
  done
  readOnlyRoot $BCKUPDIR
} 


##########################################################################
# Remove spurious log file entries
##########################################################################
cleanLogFile()
{
  # Remove tar messages about leading slashes
  sed -i "/tar: Removing.*/d" $LOGFILE

  # Remove chkconfig errors
  sed -i "/error reading information on.*/d" $LOGFILE

  # Remove stat errors
  sed -i "/stat: cannot stat.*/d" $LOGFILE
}

##########################################################################
# Print out the fancy closing data
##########################################################################
closeoutRF()
{
  echo
  echo "------------------------------------------------------------------------------"
  echo
  echo "RedFort has finished successfully.  The log file is located at:"
  echo "$LOGFILE"
  echo 
  writeToLog "Execution finished."
}


##########################################################################
# Print the "1337" banner
##########################################################################
printFancyBanner()
{
  clear
  echo "------------------------------------------------------------------------------"
  echo -e "          \033[31m RRRRR              d\033[m        FFFFFFF"
  echo -e "          \033[31mR     R             d\033[m        F"
  echo -e "          \033[31mR     R             d\033[m        F"
  echo -e "          \033[31mRRRRR     eeee      d\033[m        FFFF                t"
  echo -e "          \033[31mR    R   e    e  dddd\033[m        F      ooo    rr  ttttt"
  echo -e "          \033[31mR     R   eeee  d   d\033[m        F     o   o  r      t"
  echo -e "          \033[31mR     R  e      d   d\033[m        F     o   o  r      t"
  echo -e "          \033[31mR     R   eeee   ddd \033[m        F      ooo   r      tt"
  echo 
  echo "                            version $VERSION"
  echo "------------------------------------------------------------------------------"
  echo
}

##########################################################################
# Print the boring informational banner
##########################################################################
printBanner()
{
  clear
  echo "------------------------------------------------------------------------------"
  echo "                           R E D    F O R T"
  echo "                            version $VERSION"
  echo "------------------------------------------------------------------------------"
}


##########################################################################
# Load and process each module
##########################################################################
buildModuleList()
{
  for FILE in `find $RFDIR/modules -type f | sort`; do
    MODULE_NAME=`grep "#.*Module" $FILE | head -n 1 | sed "s/# *//" | cut -d " " -f 2-`
    FIX_POSITION=`grep "#.*RUNLEVEL" $FILE | head -n 1 | sed "s/# *//" | cut -d " " -f 2`
    UNDO_POSITION=`grep "#.*RUNLEVEL" $FILE | head -n 1 | sed "s/# *//" | cut -d " " -f 3`
    CHECK_COMMAND=`grep "#.*CHECK" $FILE | head -n 1 | sed "s/# *//" | cut -d " " -f 2`
    FIX_COMMAND=`grep "#.*FIX" $FILE | head -n 1 | sed "s/# *//" | cut -d " " -f 2`
    UNDO_COMMAND=`grep "#.*UNDO" $FILE | head -n 1 | sed "s/# *//" | cut -d " " -f 2`
    echo "$FIX_POSITION $FIX_COMMAND $MODULE_NAME" >> $FIXLIST
    echo "$UNDO_POSITION $UNDO_COMMAND $MODULE_NAME" >> $UNDOLIST
    echo "$CHECK_COMMAND" >> $CHECKLIST
    # Remove lines and sort the action lists
    sed -i "/^9999 /d" $FIXLIST
    sed -i "/^9999 /d" $UNDOLIST
    sort -g $FIXLIST -o $FIXLIST
    sort -g $UNDOLIST -o $UNDOLIST
  done
}


##########################################################################
# Handles individual actions
evaluateAction()
{
  setIFSNonPrint
  COMMAND=$1
  if [[ "$RUNORSHOW" == "RUN" && "$RUNTYPE" == "COMPLETE" || "$RUNTYPE" == "RMODS" ]]; then
    eval $COMMAND 1>>$LOGTO 2>>$LOGFILE
  else
    eval $COMMAND 1>>$LOGTO 2>>$LOGFILE
  fi
  resetIFS
}


##########################################################################
# Determines if a umask has been set to 0077/077
checkUmaskSet()
{
  if [ $# -eq 1 ]; then
     if [ `grep -i umask $1 | grep -v -e "^[[:blank:]]*#" | grep -v -e "^[[:blank:]]*$" | grep -c -v -e "[0|00]77[[:blank:]]*$"` -ne 0 ]; then
        CHKVAL=1
     else
        CHKVAL=0
     fi
  else
     echo "ERROR: Called check_umask_set without proper number of arguments." >> $LOGFILE
  fi
}


##########################################################################
# Set standard locations
setGlobalValues()
{
  RUNTYPE="COMPLETE"
  RUNMODE="FAST"
  SKIPMODULES=""
  MANIFESTFILE=""
  FINDOPTIONS="-xautofs -xdev"
  TEMPLATE="default"
  LOGTO="/dev/null"
  NEEDSREBOOT="FALSE"
  SYSTEMNAME=`hostname`
  RUNORSHOW="RUN"
  TEMPDIR="/tmp"
  LOGDIR="/root"
  PROMPTUSER="TRUE"

}


##########################################################################
# Set standard locations
setLocations()
{
  setDateStamp
  # Check for overrides to presets
  if [ "$BCKUPLOC" == "" ]; then
    BCKUPLOC=/root/.rfbackup
  fi
  if [ "$TEMPDIR" == "" ]; then
    TEMPDIR="/tmp"
  fi
  if [ "$TMPLDIR" == "" ]; then
    TMPLDIR="$RFDIR/templates/default"
  fi
  LOGFILENAME="RedFort.log"
  INCDIR="$RFDIR/includes"
  CONFDIR="$TMPLDIR/configs"
  PREBDIR="$TMPLDIR/prebuilt"
  THEMEDIR="$TMPLDIR/theme"
  MAKELIST="$TMPLDIR/req_files.txt"
  FIXLIST="$TEMPDIR/run_modules.txt"
  MODLIST="$TEMPDIR/module_list.txt"
  MODCKLIST="$TEMPDIR/module_check_list.txt"
  CHECKLIST="$TEMPDIR/check_list.txt"
  UNDOLIST="$TEMPDIR/undo_list.txt"
  RUNHISTORY="$LOGDIR/RF_History.txt"
  FINDMETHOD="$INCDIR/run.sh"
  BCKUPDIR=$BCKUPLOC/$DTSTAMP
  LOGFILE=$BCKUPDIR/$LOGFILENAME
  BCKUPCONFIGS=$BCKUPDIR/CustomConfigs/

  checkMakeDir $BCKUPLOC
  checkMakeDir $BCKUPDIR
  checkMakeFile $LOGFILE
  checkMakeFile $MODLIST
  clearFile $FIXLIST
  clearFile $UNDOLIST
  clearFile $CHECKLIST
}


##########################################################################
# Bring in the module files for use
loadAllModules()
{
  for FILE in `find $RFDIR/modules -type f | sort`; do
    . $FILE
  done
}


##########################################################################
# Print the help information
writeLogHeader()
{
  writeToLog "RedFort version: $VERSION"
  writeToLog "Detected OS: $OSNAME version $OSVER"
  writeToLog "Type of execution: "
  HN=`hostname`
  writeToLog "Hostname: $HN" 
}


##########################################################################
# Print the help information
showHelp()
{
  echo
  echo "RedFort version $VERSION"
  echo "------------------------------------------------------------------------------"
  echo "Usage: RedFort.sh [--help] [--demo | --debug | --backup | --audit]"
  echo "[--template={TEMPLATE} [--include-netshare] --manifest={MANIFEST}"
  echo "[--runmodules={MODULE_1,...,MODULE_N} | --skipmodules={MODULE_1,...,MODULE_N}]"
  echo "[--modinfo={MODULE_1,...,MODULE_N}]"
  echo
  if [ $1 -eq 1 ]; then
    echo "For detailed help run RedFort.sh --help"
  else
    echo 
    echo
    echo "--demo         : Red Fort will act like it is executing but not actually change"
    echo "                 anything."
    echo
    echo "--debug        : Red Fort will act like it is executing but not actually change"
    echo "                 anything.  All commands that would normally be run are"
    echo "                 displayed on the screen."
    echo
    echo "--backup       : Red Fort will only create backups (for use in undo mode).  No"
    echo "                 output will be made to the screen and no changes will be made"
    echo "                 to the system."
    echo
    echo "--audit        : Red Fort will run the \"check\" functions of the selected"
    echo "                 modules but will not fix anything."
    echo
    echo "--include-netshare"
    echo "               : Red Fort will include remote filesystems in searches."
    echo
    echo "--manifest={MANIFEST_FILE}"
    echo "                 Red Fort will use the specified file for comparisons when"
    echo "                 evaluating the package set that is present on the system"
    echo "                 for non-approved packages."
    echo
    echo "--template={TEMPLATE}"
    echo "               : Specifies a template to use for all module configuraitons."
    echo
    echo "--modinfo={MODULES}"
    echo "               : Shows detailed information about the items which are fixed by"
    echo "                 each module.  Multiple modules may be separated by a comma,"
    echo "                 or the option \"all\" will show information on all modules."
    echo
    echo "--runmodules={MODULES}"
    echo "               : Executes only the specified modules.  Multiple modules may be"
    echo "                 separated by a comma.  Execution will occur in the specified"
    echo "                 module order."
    echo
    echo "--skipmodules={MODULES}"
    echo "               : Skips only the specified modules.  Multiple modules may be"
    echo "                 separated by a comma.  Execution will occur in the specified"
    echo "                 module order."
    echo
    echo "--help         : This screen."
    echo 
    echo "------------------------------------------------------------------------------"
    echo "                      T   E   M   P   L   A   T   E   S"
    echo "------------------------------------------------------------------------------"
    echo
    # Generate the list of platforms
    echo
    echo "------------------------------------------------------------------------------"
    echo
    cd $RFDIR
  fi
}
