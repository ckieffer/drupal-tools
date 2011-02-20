#!/bin/bash
PATH="/bin:/usr/bin:/opt/local/bin"
export PATH

###################################################################################################
#
#  Update Drupal 6 or 7 core locally, then remotely via SSH and SVN
#
#  Author: Chad Kieffer, ckieffer at gmail dot com
#
#  This script updates a local subversion working copy of Drupal 6 or 7 and then the corresponding 
#  remote production copy. The root .htaccess file in both the working and remote copies is 
#  not touched. Updates to the .htaccess file must be managed manually. The sites/example.sites.php
#  introduced in Drupal 7 is not touched either. 
#
#  Install/Configure
#  1) Save the script locally and make it executable
#  2) Set path and connection variables in drupal_info.sh
#  
#  Use:
#  1) Download Drupal core update from drupal.org to the $DownloadsPath specified in drupal_info.sh
#  2) Run the script, ./drupal_update.sh
#  3) Follow the instructions provided
#
#  @TODO Handle file deletions via svn remove
#  @TODO Support -dev versions
#
###################################################################################################

# Include Drupal path and remote server connection settings
ScriptDir=`dirname $0`
source $ScriptDir/drupal_info.sh

# Which version are we updating, 6 or 7?
DrupalPkg=$(ls $DownloadsPath/drupal-*.*.tar.gz | head -n 1)
DrupalPkgFile=${DrupalPkg##*/}           # drupal-6.20.tar.gz
DrupalPkgBase=${DrupalPkgFile%%.tar*}    # drupal-6.20
CoreName=${DrupalPkgFile%%-*}            # drupal
FullVersion=${DrupalPkgBase#$CoreName-*} # 6.20   
Version=${FullVersion%.*}                # 6

# echo -e "ScriptDir: $ScriptDir"
# echo -e "DownloadsPath: $DownloadsPath"
# echo -e "DrupalPkg: $DrupalPkg"
# echo -e "DrupalPkgFile: $DrupalPkgFile"
# echo -e "DrupalPkgBase: $DrupalPkgBase"
# echo -e "CoreName: $CoreName"
# echo -e "FullVersion: $FullVersion"
# echo -e "Version: $Version"
# exit 0

if [ "$Version" == 7 ]; then
  LocalDrupal=$LocalDrupal7
  RemoteDrupal=$RemoteDrupal7
else
  LocalDrupal=$LocalDrupal6
  RemoteDrupal=$RemoteDrupal6
fi

echo -e "\n Beginning update of local Drupal $Version to $DrupalPkgBase"

# Proceed if a downloaded module exists
if [ -e "$DrupalPkg" ]; then
  # Unpack core update package and remove files we don't want overwritten
  tar xfzp $DrupalPkg -C $DownloadsPath
  rm $DownloadsPath/$DrupalPkgBase/.htaccess
  if [ -f $DownloadsPath/$DrupalPkgBase/sites/example.sites.php ]; then
    rm $DownloadsPath/$DrupalPkgBase/sites/example.sites.php
  fi
  mv $DownloadsPath/$DrupalPkgBase $DownloadsPath/$LocalDrupal
  cd $DownloadsPath
  tar cfz $LocalDrupal.tar.gz $LocalDrupal
  tar xfzp $DownloadsPath/$LocalDrupal.tar.gz -C $LocalBase
  
  # Prompt to test the local install
  echo -e "\n Local install files updated."
  sleep 3
  echo -e "\n Run the upgrade.php script for each local site."
  echo -e " Take a moment to test each local site before committing."
  echo -ne "\n Did you test? Ready to commit? (y/n): "
  read Proceed
  echo -e ""
  
  # Proceed with commit
  if [ "$Proceed" == "y" ]; then
    # Add new files to the repository
    svn status $LocalBase/$LocalDrupal | grep "^\?" | awk '{print $2}' | xargs svn add
    echo -e "\n Checking in $DrupalPkgBase update \n"
    svn ci -m 'Update to $DrupalPkgBase' $LocalBase/$LocalDrupal/themes $LocalBase/$LocalDrupal/scripts $LocalBase/$LocalDrupal/profiles $LocalBase/$LocalDrupal/modules $LocalBase/$LocalDrupal/misc $LocalBase/$LocalDrupal/includes $LocalBase/$LocalDrupal/*.*
    # Connect to remote server and run svn update
    echo -e "\n Updating remote installation to $DrupalPkgBase \n"
    ssh $SSHConnect svn update "$RemoteBase/$RemoteDrupal"
    # Cleanup
    echo -e "\n Cleaning up downloads and working files"
    rm -rf $DownloadsPath/$LocalDrupal
    rm $DownloadsPath/$LocalDrupal.tar.gz
    rm $DrupalPkg
  # Allow the user to manually revert the update or commit manually
  else
    echo -e "\n\n Okay, the Drupal $Version update has not been checked in."
    echo -e "\n Use 'svn revert' to roll back local working copies or handle this update manually."
    echo -e "\n The downloaded package and files remain at $DownloadsPath"
  fi
else
  echo -e "\n Drupal $Version package not found in $DownloadsPath"
fi

exit 0
