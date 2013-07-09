#!/runFixesbin/bash
#  
# Version 0.8.0
# Author: Brian "Hermit" Mork
#
# Module: Module Template
# ModInfo: modtemp         Sample module showing standard format/tasks
# RUNLEVEL 9999 9999 
# CHECK check_modtemp
# FIX fix_modtemp
# UNDO undo_modtemp
#
# Note that for RUNLEVEL the first value is the order of the "FIX"
# function, and the second is the order of the "UNDO" function.
# The special value of 9999 specifies that this module should not 
# be automatically executed but rather run only when specified via
# a --runmodules command.
#

#####################################################################
# Global section
#
#   This section is used to identify any variables or required files
#   that the module will use.  Red Fort provides several references
#   that may be used to find those files within the standard
#   framework locations, specifically:
#     - $RFDIR points to the base Red Fort location, or where the
#       rf.sh file is located
#     - $INCDIR points to the includes directory, where cross-module
#       functions and helpers are stored
#     - $TMPLDIR points to the templates directory, where configuration
#       files, themes, and pre-built files are stored.  A template
#       is a collection of these items that specify a unique
#       baseline or configuration set.  These items may also be
#       referenced by their own variables, namely $CONFDIR, $PREBDIR,
#       $THEMEDIR, and $MAKELIST.
#     - $BCKUPDIR points to current backup directory, where backups
#       should be stored
#     - $TEMPDIR points to the temporary directory that can be used
#       for transient storage
MODTEMPCONFIG=$CONFDIR/mod-temp.conf
MODTEMPBACKUP=$BCKUPDIR/mod-temp.back

#####################################################################
# Check section, function name specified in "CHECK" comment above
#
#    A check section is used to determine if a system is in compliance
#    with the changes that would be introduced by the module.  For
#    instance, if a module would normally set a series of file
#    permissions (e.g. this module) the check section would check each
#    file whose permissions would be changed and identify which ones
#    are not currently at the desired final setting.  Using "check"
#    functions allows for the rapid auditing of a system against a
#    known baseline.
check_modtemp()
{
  reportModuleRunning "Module Template (modtemp)"
  reportStatusHeading "Evaluating file permissions"
  while read ENTRY; do
    getKeyValuePair $ENTRY
    fileExists $KEY
    if [ "$ISFILE" == "yes" ]; then
      CPERM=`stat -c %a $KEY`
      comparePermissions $CPERM $VALUE
      if [ "$PERMEVAL" == "MORE" ]; then
        reportSubTaskStatus "$KEY" "FAIL" "red"
      fi
    fi
  done < <( stripFileComments $MODTEMPCONFIG )
  reportSubTaskStatus "File permission evaluations" "DONE"
}

#####################################################################
# Fix section, function name specified in "FIX" comment above
fix_modtemp()
{
  reportModuleRunning "Module Template (modtemp)"
  reportStatusHeading "Correcting file permissions"
  while read ENTRY; do
    getKeyValuePair $ENTRY
    fileExists $KEY
    if [ "$ISFILE" == "yes" ]; then
      CPERM=`stat -c %a $KEY`
      writeKeyValuePair "$KEY:$CPERM" "$MODTEMPBACKUP"
      evaluateAction "chmod $VALUE $KEY"
    fi
  done < <( stripFileComments $MODTEMPCONFIG )
  reportSubTaskStatus "Correcting file permissions" "DONE"
}
#####################################################################
# Undo section, function name specified in "UNDO" comment above

