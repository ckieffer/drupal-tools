#!/bin/bash
PATH="/bin:/usr/bin:/opt/local/bin"
export PATH

###################################################################################################
#
#  Update a shared or site-specific Drupal 6 or 7 module locally, then remotely via SSH and SVN
#
#  Author: Chad Kieffer, ckieffer at gmail dot com
#  
#  This script streamlines the update and install of Drupal 6 and 7 modules in a local subversion 
#  working copy and then in a remote production installation. It assumes that you're using  
#  Subversion, SSH to access remote installations, and that modules are installed in either 
#  sites/all/modules/ or sites/MySite.com/modules/. 
#
#  Install/Configure
#  1) Save the script locally and make it executable
#  2) Set path and connection variables in drupal_info.sh
#  
#  Use:
#  1) Visit the Drupal available updates report
#  2) Download any and all available updates to $DownloadsPath specified in drupal_info.sh
#     Note: You'll run this script for each update downloaded, it won't update all at once
#  3) Run the script, ./drupal_module_update.sh
#  4) Follow the instructions provided:
#     - Specify if the module's installed for one or all sites
#     - Visit the local Drupal update.php script to run required database updates
#     - Test the update locally
#     - Commit the update
#     - Run the update remotely
#     - Visit the remote Drupal update.php script to run required database updates
#
#  @TODO Handle file deletions in updated packages via svn remove
#
###################################################################################################

# Include Drupal path and remote server connection settings
source drupal_info.sh

# Determine the first module downloaded to and listed in $DownloadsPath
DownloadsPkgFilePath=$(ls $DownloadsPath/*-*.x-*.tar.gz | head -n 1)
PkgFileName=${DownloadsPkgFilePath##*/}  # advanced_help-7.x-1.0-beta1.tar.gz
PkgBaseName=${PkgFileName%%.tar*}        # advanced_help-7.x-1.0-beta1
ModuleName=${PkgBaseName%%-*}            # advanced_help
FullVersion=${PkgBaseName#$ModuleName-*} # 7.x-1.0-beta1    
                                         # 7.x-2.x-dev
Version=${FullVersion%.x-*.*}            # 7 #Version=${FullVersion%.x*} 

# Which version are we updating, 6 or 7?
if [ "$Version" == 7 ]; then
  LocalDrupal=$LocalDrupal7
  RemoteDrupal=$RemoteDrupal7
elif [ "$Version" == 6 ]; then
  LocalDrupal=$LocalDrupal6
  RemoteDrupal=$RemoteDrupal6
else 
	echo -e "Unable to detemine version."
	echo -e "PkgFileName: $PkgFileName"
	echo -e "PkgBaseName: $PkgBaseName"
	echo -e "ModuleName: $ModuleName"
	echo -e "FullVersion: $FullVersion"
	echo -e "Version: $Version"
	exit 0
fi

# Paths to drupal/sites
LocalSites="$LocalBase/$LocalDrupal/sites"
RemoteSites="$RemoteBase/$RemoteDrupal/sites"

# Bail if a module's not found
if [ "$ModuleName" == "" ]; then
  echo -e "\n No module packages found in $DownloadsPath"
  echo -e "\n Nothing to do!"
  exit 0
else
  echo -e "\n Beginning update to $PkgBaseName"
fi

# Is this a shared or site-specific module?
echo -ne "\nEnter site (ex. MySite.com) or leave empty for all: "
read Site

# Set local and remote paths
if [ "$Site" == "" ]; then 
  LocalTgtPath="$LocalSites/all/modules"
  RemotePath="$RemoteSites/all/modules"
else 
  LocalTgtPath="$LocalSites/$Site/modules"
  RemotePath="$RemoteSites/$Site/modules"
fi

# Unpack module package and check it in
update_module() 
{
  # Move the module to the Drupal module directory 
  mv "$DownloadsPkgFilePath" "$LocalTgtPath"
  # Unpack the module
  echo -e "\n Unpacking $ModuleName update \n"
  tar xvfzp $LocalTgtPath/$PkgFileName -C $LocalTgtPath
  echo -e "\n $ModuleName unpacked"

  # Prompt to test new/updated module locally
  echo -e "\n Visit the local Drupal upgrade.php script or install the module."
  echo -e "\n Take a moment to test this update locally before committing."
  echo -ne "\nReady to commit it? (y/n): "
  read Proceed
  
  # Proceed with commit
  if [ "$Proceed" == "y" ]; then
    # Add new files to the repository
    svn status $LocalTgtPath/$ModuleName | grep "^\?" | awk '{print $2}' | xargs svn add
    
    # Checkin the updates
    svn ci -m "Updated to $PkgBaseName" $LocalTgtPath/$ModuleName
    
    # Cleanup
    rm $LocalTgtPath/$PkgFileName
    
    # Connect to remote server to update the module there
    echo -e "\nNow to update the module via SVN on the remote server\n"
    ssh $SSHConnect svn update "$RemotePath"
    
    # Display confirmation
    echo -e "\n\n The update/install of $ModuleName is complete!"
    echo -e "\n Visit the remote Drupal upgrade.php script or install the module."
    
  # Allow the user to manually revert the update or checkin manually
  else
    echo -e "\n\n Okay, $ModuleName has not been checked in."
    echo -e "\n Use 'svn revert' to roll back local working files or handle its update manually."
    echo -e "\n The downloaded package remains at $LocalTgtPath/$PkgFileName"
  fi
}

# Check that a module update package exists in the download folder
if [ -e "$DownloadsPkgFilePath" ]; then
  # Update existing module
  if [ -d $LocalTgtPath/$ModuleName ]; then
    update_module

  # The module doesn't exist for the specified Drupal site
  else
    echo -e "\n\n Update error: $LocalTgtPath/$ModuleName doesn't exist."
  
    # Install as a new module?
    if [ -d $LocalTgtPath ]; then
      echo -ne "Do you want to install $ModuleName there? (y/n): "
      read $Install
      if [ "$Install" == "n" ]; then
        echo -e "\n Okay, maybe later then."
        exit 0
      else
        update_module
      fi
    fi
  fi

  echo -e "\n Done!"
  exit 0
  
else
  echo -e "\n\nError: A module package wasn't found."
  echo -e "\nDid you save the update package to $DownloadsPath?"
  exit 1
fi
