#!/bin/bash
PATH="/bin:/usr/bin:/opt/local/bin"
export PATH

###################################################################################################
#
#  Update Drupal 6 core locally, then remotely via SSH and SVN
#
#  Author: Chad Kieffer, ckieffer at gmail dot com
#
#  This script updates a local subversion working copy of Drupal 6 and then the corresponding 
#  remote production copy. The root .htaccess file in both the working remote copies is 
#  not touched.
#
#  Install/Configure
#  1) Save the script locally and make it executable
#  2) Set path and connection variables in drupal_info.sh
#  
#  Use:
#  1) Download the Drupal update drupal.org to $DownloadsPath specified in drupal_info.sh
#  2) Run the script, ./drupal_update.sh
#  3) Follow the instructions provided
#
#  @TODO Handle file deletions via svn remove
#  @TODO Pause the script to allow local testing of update before svn commit
#
###################################################################################################

# Include Drupal path and remote server connection settings
source drupal_info.sh

# Get the path/name of the Drupal update package in $DownloadsPath
DrupalPkg=$(ls $DownloadsPath/*-6.*.tar.gz | head -n 1)
DrupalPkgFile=${DrupalPkg##*/}
DrupalPkgBase=${DrupalPkgFile%%.tar*}

echo "Updating to $DrupalPkgBase"

# Proceed if a downloaded module exists
if [ -e "$DrupalPkg" ]; then
  tar xvfzp $DownloadsPath/$DrupalPkgFile -C $DownloadsPath
  rm $DownloadsPath/$DrupalPkgBase/.htaccess
  mv $DownloadsPath/$DrupalPkgBase $DownloadsPath/$LocalDrupal
  cd $DownloadsPath
  tar cfz $LocalDrupal.tar.gz $LocalDrupal
  tar xvfzp $DownloadsPath/$LocalDrupal.tar.gz -C $LocalBase
  # @TODO Add any new files to the repository
  #svn status $LocalBase/$LocalDrupal | grep "^\?" | awk '{print $2}' | xargs svn add
  svn ci -m 'Updated to $DrupalPkgBase' $LocalBase/$LocalDrupal/themes $LocalBase/$LocalDrupal/scripts $LocalBase/$LocalDrupal/profiles $LocalBase/$LocalDrupal/modules $LocalBase/$LocalDrupal/misc $LocalBase/$LocalDrupal/includes $LocalBase/$LocalDrupal/*.*
  # Cleanup
  rm -rf $DownloadsPath/$LocalDrupal
  rm $DownloadsPath/$LocalDrupal.tar.gz
  rm $DrupalPkg
  # Connect to remote server and run svn update
  ssh $SSHConnect svn update "$RemotePath/$RemoteDrupal"
fi

exit 0
