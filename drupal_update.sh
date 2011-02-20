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
#  not touched. Updates to the .htaccess file must be managed manually.
#
#  Install/Configure
#  1) Save the script locally and make it executable
#  2) Set path and connection variables in drupal_info.sh
#  
#  Use:
#  1) Download the Drupal update from drupal.org to the $DownloadsPath specified in drupal_info.sh
#  2) Run the script, ./drupal_update.sh
#  3) Follow the instructions provided
#
#  @TODO Add any new files to the repository
#  @TODO Handle file deletions via svn remove
#
###################################################################################################

# Include Drupal path and remote server connection settings
source ./drupal_info.sh

# Which version are we updating, 6 or 7?
echo -ne "\nWhich version of Drupal, 6 or 7 (leave empty 6): "
read Version

if [ "$Version" == 7 ]; then
  LocalDrupal=$LocalDrupal7
  RemoteDrupal=$RemoteDrupal7
else
  LocalDrupal=$LocalDrupal6
  RemoteDrupal=$RemoteDrupal6
fi

# Get the path/name of the Drupal update package in $DownloadsPath
DrupalPkg=$(ls $DownloadsPath/*-$Version.*.tar.gz | head -n 1)
DrupalPkgFile=${DrupalPkg##*/}
DrupalPkgBase=${DrupalPkgFile%%.tar*}

echo "Updating local Drupal $Version to $DrupalPkgBase"

# Proceed if a downloaded module exists
if [ -e "$DrupalPkg" ]; then
  tar xvfzp $DownloadsPath/$DrupalPkgFile -C $DownloadsPath
  rm $DownloadsPath/$DrupalPkgBase/.htaccess
  rm $DownloadsPath/$DrupalPkgBase/sites/example.sites.php
  mv $DownloadsPath/$DrupalPkgBase $DownloadsPath/$LocalDrupal
  cd $DownloadsPath
  tar cfz $LocalDrupal.tar.gz $LocalDrupal
  tar xvfzp $DownloadsPath/$LocalDrupal.tar.gz -C $LocalBase

  # Prompt to test the local install
  echo -e "\n Visit the Drupal upgrade.php script for each local site."
  echo -e "\n Take a moment to test this update for each local site before committing.\n"
  echo -e "\n You'll also need to check for new files and add them with svn add.\n"
  echo -ne "\nReady to commit it? (y/n): "
  read Proceed
  
  # Proceed with commit
  if [ "$Proceed" == "y" ]; then
	  # @TODO Add any new files to the repository
	  #svn status $LocalBase/$LocalDrupal | grep "^\?" | awk '{print $2}' | xargs svn add
		echo "Checking in $DrupalPkgBase update"
	  svn ci -m 'Updated to $DrupalPkgBase' $LocalBase/$LocalDrupal/themes $LocalBase/$LocalDrupal/scripts $LocalBase/$LocalDrupal/profiles $LocalBase/$LocalDrupal/modules $LocalBase/$LocalDrupal/misc $LocalBase/$LocalDrupal/includes $LocalBase/$LocalDrupal/*.*
	  # Connect to remote server and run svn update
		echo "Updating remote installation to $DrupalPkgBase"
	  ssh $SSHConnect svn update "$RemoteBase/$RemoteDrupal"
	  # Cleanup
		echo "Cleaning up downloads and working files"
	  rm -rf $DownloadsPath/$LocalDrupal
	  rm $DownloadsPath/$LocalDrupal.tar.gz
	  rm $DrupalPkg
  # Allow the user to manually revert the update or checkin manually
  else
    echo -e "\n\n Okay, the Drupal $Version update has not been checked in."
    echo -e "\n Use 'svn revert' to roll back local working copies or handle this update manually."
    echo -e "\n The downloaded package and files remain at $DownloadsPath"
  fi		
else
	echo -e "Drupal $Version package not found in $DownloadsPath"
fi

exit 0
