#!/bin/bash
#  
#  Software: Red Fort
#  Module: General Helper Functions
#  Author: Brian "Hermit" Mork
#  Version: 0.8.0 
#  Modified: 2013-07-08
#
##########################################################################

##########################################################################
# Asks a question and gets a response
ask()
{
  VALID="FALSE"
  while [ "$VALID" = "FALSE" ]; do
    read -p "$1 [Y/N] " ANS
    case $ANS in
      [Yy]) RETVAL=1; VALID="TRUE";;
      [Nn]) RETVAL=0; VALID="TRUE";;
      *) echo "Invalid choice."
    esac
  done
  return $RETVAL
}

##########################################################################
# Clear out a file (if it exists)
clearFile()
{
  if [ -e $1 ]; then
    rm -f $1
  fi
}


##########################################################################
# Set read-only to root for a file/directory
readOnlyRoot()
{
  # Check for existence
  if [ -e $1 ]; then
    # Set ownership
    chown -R root:root $1
    if [ -d $1 ]; then
      # Directories need execute permission as well as read
      chmod 500 $1
    else
      # Files/everything else only need read
      chmod 400 $1
    fi
  fi  
}


##########################################################################
# "Press any key to continue..."
paktc()
{
   read -p "Press any key to continue..." -n 1 throwaway
   echo
}


##########################################################################
# Debug function: pause execution
debugPause()
{
  if [ "$1" != "" ]; then
    echo "Paused at: $1"
  else
    echo "DEBUG: Execution Paused"
  fi
  sleep 600
}


##########################################################################
# Quick test/reporting for existence of a file/directory
fileExists()
{
  if [ -f $1 ]; then
    ISFILE="yes"
  else
    ISFILE="no"
  fi
}


##########################################################################
# Quick test/reporting for existence of a file/directory
dirExists()
{
  if [ -d $1 ]; then
    ISDIR="yes" 
  else
    ISDIR="no"
  fi
}


##########################################################################
# Check if a file exists, make it if not
checkMakeFile()
{
  fileExists $1
  if [ "$ISFILE" == "no" ]; then
    touch $1
  fi  
}


##########################################################################
# Check if a directory exists, make it if not
checkMakeDir()
{
  dirExists $1
  if [ "$ISDIR" == "no" ]; then
    mkdir -p $1
  fi  
}


##########################################################################
# Ignores commented lines
stripFileComments()
{
   SOURCEFILE=$1
   cat $SOURCEFILE 2>>$LOGFILE | grep -v "^[[:blank:]]*#" | cut -d "#" -f 1 | grep -v -e "^[[:blank:]]*$"
}


##########################################################################
# Ignores commented lines in streams
stripStreamComments()
{
   grep -v "^[[:blank:]]*#" | cut -d "#" -f 1 | grep -v -e "^[[:blank:]]*$" -
}


##########################################################################
# Return colon-separated entries as value pairs
getKeyValuePair()
{
  PAIRSET=$1
  KEY=`echo $PAIRSET | cut -d ":" -f 1`
  VALUE=`echo $PAIRSET | cut -d ":" -f 2`
}


##########################################################################
# Return colon-separated entries as value pairs
writeKeyValuePair()
{
  PAIRSET=$1
  SAVEFILE=$2
  echo "$PAIRSET" >> $SAVEFILE
}


##########################################################################
# Determines if a permission set is more restrictive
# Takes current permissions ($1) and target permissions ($2) in 4 character octal form
# to determine if the current are more permissive than the target
comparePermissions()
{
   CURRENTPERMISSION="$1"
   TARGETPERMISSION="$2"
   PERMEVAL="LESS"
   # Correct for automatic truncation of leading 0 on file/directory permissions
   if [ ${#CURRENTPERMISSION} -eq 3 ]; then
      CURRENTPERMISSION="0""$CURRENTPERMISSION"
   fi
   if [ ${#TARGETPERMISSION} -eq 3 ]; then
      TARGETPERMISSION="0""$TARGETPERMISSION"
   fi
   declare -i COMPAREPOINT=1
   while [ $COMPAREPOINT -ne 4 ]; do
      declare -i CCOMP=`echo "$CURRENTPERMISSION" | cut -c $COMPAREPOINT`
      declare -i TCOMP=`echo "$TARGETPERMISSION" | cut -c $COMPAREPOINT`
      if [ $CCOMP -gt $TCOMP ]; then
         PERMEVAL="MORE"
      fi
      COMPAREPOINT=$COMPAREPOINT+1
   done
}


##########################################################################
# Set IFS to a comma
setIFSComma()
{
  IFS=","
}


##########################################################################
# Set IFS to a non-readable character
setIFSNonPrint()
{
  IFS=$'\012'
}


##########################################################################
# Reset IFS value
resetIFS()
{
  unset IFS
}


##########################################################################
# Set the date/time stamp
setDateStamp()
{
  DTSTAMP=`date --rfc-3339=date | sed "s/\-//g"``date | cut -c 12-19 | sed "s/\://g"`
}

##########################################################################
# Check for root
checkForRoot()
{
  if [ $EUID -ne 0 ]; then
    echo "You must be root to execute this scrpt."
    exit 64
  fi
}
