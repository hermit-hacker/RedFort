#!/bin/bash
#  
#  Software: RedFort
#  Module: RF Argument Helper Functions 
#  Author: Brian "Hermit" Mork
#  Version: 0.8.0
#  Modified: 2013-07-08
#
##########################################################################


##########################################################################
# Read in all command line parameters
##########################################################################
readCommandParameters()
{
  if [ "$#" -gt 0 ]; then
    PROMPTUSER="FALSE"
    for ARGUMENT in $*; do CLOPTION=`echo $ARGUMENT | cut -d "=" -f 1`
      CLSETTING=`echo $ARGUMENT | cut -d "=" -f 2`
      parseParameter $CLOPTION $CLSETTING
    done
  fi
}

##########################################################################
# Parse parameters
##########################################################################
parseParameter()
{
  case $1 in
    "--help") 			showHelpCL 0;;
    "--modinfo") 		showModInfo $2;;
    "--audit")                  setAuditMode;;
    "--demo") 			setDemoMode;;
    "--debug")			setDebugMode;;
    "--backup")			setBackupMode;;
    "--mode")			setMode $2;;
    "--template")		setTemplate $2;;
    "--include-netshare")	setFindOptions netshare;;
    "--manifest")		setManifest $2;;
    "--skipmodules")		setModulesToSkip $2;;
    "--runmodules")		setModulesToRun $2;;
    "--backupdir")              setBackupLocation $2;;
    "--tempdir")                setTempLocation $2;;
    *)				showHelpCL 1;;
  esac
}

##########################################################################
# Handle a help request/bad request
##########################################################################
showHelpCL()
{
  showHelp $1
  exit $1
}


##########################################################################
# Show module information
##########################################################################
showModInfo()
{
  printBanner
  cd $RFDIR/modules
  if [ `echo $ARGVAL | sed -e "s/a/A/" | sed -e "s/l/L/g"` == "ALL" ]; then
    for MODFILE in `ls`; do
      modInfo $MODFILE
    done
  else
    setIFSComma
    for MODULE in $1; do
      MODFILE=`grep "#.*ModInfo: $MODULE" $RFDIR/modules/* | cut -d : -f 1`
      if [ "$MODFILE" != "" ]; then
        modinfo $MODFILE
      else
        echo "$MODULE is not a valid module."
      fi
    done
    resetIFS
  fi
  exit 0
}


##########################################################################
# Set backup directory 
##########################################################################
setBackupLocation()
{
  dirExists $1
  if [ "$ISDIR" == "no" ]; then
    echo "Creating backup directory: $1"
    checkMakeDir $1
  fi    
  BCKUPLOC="$1"
}


##########################################################################
# Set temporary directory
##########################################################################
setTempLocation()
{
  dirExists $1
  if [ "$ISDIR" == "no" ]; then
    echo "Creating temporary directory: $1"
    checkMakeDir $1
  fi
  TEMPDIR="$1"
}

##########################################################################
# Show module information
##########################################################################
modInfo()
{
  echo
  grep "#  Module:" $1 | cut -d " " -f 3-;
  echo "----------------------------------------";
  grep "# HELPTEXT #" $1 | cut -d "#" -f 3-;
  echo
}


##########################################################################
# Set a selected mode
##########################################################################
setMode()
{
  case $1 in
    "fast")		RUNMODE="FAST";;
    "guided")		RUNMODE="GUIDED";;
    "quiet")		RUNMODE="QUIET";;
    "undo")		launchUndoMenu;;
    *)			showHelpCL 1;;
  esac
}


##########################################################################
# Enable debug mode
##########################################################################
setDebugMode()
{
  RUNORSHOW="SHOW"
  RUNTYPE="DEBUG"
  LOGTO="/dev/stdout"
  FINDMETHOD="$INCDIR/show.sh"
}


##########################################################################
# Enable audit mode
##########################################################################
setAuditMode()
{
  RUNORSHOW="RUN"
  RUNTYPE="AUDIT"
  LOGTO="/dev/stdout"
  FINDMETHOD="$INCDIR/run.sh"
}

##########################################################################
# Enable demo mode
##########################################################################
setDemoMode()
{
  RUNORSHOW="SHOW"
  RUNTYPE="DEMO"
  FINDMETHOD="$INCDIR/show.sh"
}


##########################################################################
# Enable debug mode
##########################################################################
setBackupMode()
{
  RUNORSHOW="SHOW"
  RUNTYPE="BACKUP"
  FINDMETHOD="$INCDIR/show.sh"
}


##########################################################################
# Choose a template
##########################################################################
setTemplate()
{
  if [ -d $RFDIR/$1 ]; then
    TEMPLATE="$!"
  else
    echo "The requested template ($1) does not exist."
    exit 1
  fi
}


##########################################################################
# Alter the options for find commands
##########################################################################
setFindOptions()
{
  if [ $1 == "netshare" ]; then
    FINDOPTIONS=""
  else
    FINDOPTIONS="-xautofs -xdev" 
  fi
}


##########################################################################
# Choose a manifest file
##########################################################################
setManifest()
{
  if [ -f $1 ]; then
    MANIFESTFILE=$1
  else
    echo "The requested manifest ($1) does not exist."
  fi
}


##########################################################################
# Set modules that should be skipped
##########################################################################
setModulesToSkip()
{
  clearFile $MODLIST
  setIFSComma
  for MODULE in $1; do
    MODFILE=`grep "#.*ModInfo: $MODULE" $RFDIR/modules/* | cut -d : -f 1`
    echo "MODFILE $MODFILE"
    if [ "$MODFILE" != "" ]; then
      FIXCMD=`grep "#.*FIX" $MODFILE | head -n 1 | cut -d " " -f 3`
      CHECKCMD=`grep "#.*CHECK" $MODFILE | head -n 1 | cut -d " " -f 3`
      sed -i -e "/$CHECKCMD/d" $CHECKLIST
      sed -i -e "/$FIXCMD/d" $FIXLIST
    else
      echo "$MODULE is not a valid module."
      showHelpCL 1
    fi
  done
  resetIFS
  sort -g $FIXLIST -o $FIXLIST
}


##########################################################################
# Set modules that should be executed
##########################################################################
setModulesToRun()
{
  RUNORSHOW="RUN"
  RUNTYPE="RMODS"
  clearFile $MODLIST
  clearFile $MODCKLIST
  setIFSComma
  for MODULE in $1; do
    MODFILE=`grep "#.*ModInfo: $MODULE" $RFDIR/modules/* | cut -d : -f 1`
    if [ "$MODFILE" != "" ]; then
      FIXCMD=`grep "#.*FIX" $MODFILE | head -n 1 | cut -d " " -f 3`
      CHECKCMD=`grep "#.*CHECK" $MODFILE | head -n 1 | cut -d " " -f 3`
      FIXPOS=`grep "#.*RUNLEVEL" $MODFILE | head -n 1 | sed "s/# *//" | cut -d " " -f 2`
      echo $FIXPOS $FIXCMD >> $MODLIST
      echo $CHECKCMD >> $MODCKLIST
    else
      echo "$MODULE is not a valid module."
      showHelpCL 1
    fi
  done
  resetIFS
  clearFile $FIXLIST
  clearFile $CHECKLIST
  sort -g $MODLIST -o $FIXLIST
  cat $MODCKLIST > $CHECKLIST
}


##########################################################################
# Clear out unneeded modules
##########################################################################
removeExtraneousModules()
{
  if [ "$1" == "COMPLETE" ]; then
    sed -i "/^9999 /d" $FIXLIST
    sed -i "/^9999 /d" $UNDOLIST
  fi
}
