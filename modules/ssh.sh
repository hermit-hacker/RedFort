#!/runFixesbin/bash
#  
# Version 0.8.0
# Author: Brian "Hermit" Mork
#
# Module: SSH
# ModInfo: ssh             Correct SSH settings
# RUNLEVEL 10 990
# CHECK check_ssh
# FIX fix_ssh
# UNDO undo_ssh

#####################################################################
# Global section
MODSSHDCONFIG=$CONFDIR/mod-sshd.conf
MODSSHCONFIG=$CONFDIR/mod-ssh.conf
MODSSHDBACKUP=$BCKUPDIR/mod-sshd.back
MODSSHBACKUP=$BCKUPDIR/mod-ssh.back
SSHDCONFIG=/etc/ssh/sshd_config
SSHCONFIG=/etc/ssh/ssh_config

#####################################################################
# Check section
check_ssh()
{
  reportModuleRunning "SSH (ssh)"

  # sshd_config
  reportStatusHeading "Checking SSHD configuration"
  fileExists $SSHCONFIG
  if [ "$ISFILE" == "yes" ]; then
    while read ENTRY; do
      getKeyValuePair $ENTRY
      getUnixSetting $KEY $SSHDCONFIG
      if [ "$UVALUE" == "NOTHINGFOUND" ]; then
        setModuleFail
        reportSubTaskStatus "Missing configuration: $KEY" "FAIL" "red"
      elif [ "$UVALUE" != "$VALUE" ]; then
        setModuleFail
        reportSubTaskStatus "Incorrect configuration: $KEY" "FAIL" "red"
      fi
    done < <( stripFileComments $MODSSHDCONFIG )
  else
    setModuleFail
    reportSubTaskStatus "Missing file: $SSHDCONFIG" "FAIL" "red"
  fi

  # ssh_config
  reportStatusHeading "Checking SSH client configuration"
  fileExists $SSHCONFIG
  if [ "$ISFILE" == "yes" ]; then
    while read ENTRY; do
      getKeyValuePair $ENTRY
      getUnixSetting $KEY $SSHCONFIG
      if [ "$UVALUE" == "$NOTHINGFOUND" ]; then
        setModuleFail
        reportSubTaskStatus "Missing configuration: $KEY" "FAIL" "red"
      elif [ "$UVALUE" != "$VALUE" ]; then
        setModuleFail
        reportSubTaskStatus "Incorrect configuration: $KEY" "FAIL" "red"
      fi
    done < <( stripFileComments $MODSSHCONFIG )
  else
    setModuleFail
    reportSubTaskStatus "Missing file: $SSHCONFIG" "FAIL" "red"
  fi

  reportModuleComplete "SSH (ssh)"
}

#####################################################################
# Fix section, function name specified in "FIX" comment above
fix_modtemp()
{
  echo "Not implemented yet."
}
#####################################################################
# Undo section, function name specified in "UNDO" comment above

