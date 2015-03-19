# salt-windows-dev 

## Description
This is a powershell script that sets up the development environment for salt.
All dependencies are installed.
The dependencies reside in two zip files found on http://docs.saltstack.com/downloads/windows-deps/
- salt32.zip
- salt64.zip

This has only been tested in a 64bit environment... although it should work in either.

## Usage
If you have network connectivity you can run this script on the machine you wish to set up with the development environment. If you need to set this up on a closed network, the two zipfiles can be downloaded and placed somewhere on your network or machine. Just change the $strWindowsRepo variable in the script to point to the location of the two zip files. eg:
```
$strWindowsRepo = "\\NetworkShare\salt\repo"
```
If you put this script in the same directory with the zip files this value can be "Convert-Path .", without the quotes. eg:
```
$strWindowsRepo = Convert-Path .
```
## Clone Salt
After running this script, pull the branch of salt you want to work on from github. Then go into the salt directory and run the following command:
```
python setup.py install
```

## Build Salt (2015.2 development branch and later)
Building salt has additional requirements not installed by this script. You'll need to install the NullSoft installer. That can be downloaded here: http://sourceforge.net/projects/nsis/files/NSIS%203%20Pre-release/3.0b1/nsis-3.0b1-setup.exe/download

### Build Steps
The build folders for windows are in the Salt repository as follows:
```
<parent folder>\salt\pkg\windows
```

The ```buildenv``` folder contains files that will be installed along with salt. The ```installer``` folder contains the files needed to create the .exe.
- Go into the ```installer``` folder and edit the file named: ```Salt-Minion-Setup.nsi```
- Change the ```PRODUCT_VERSION``` variable to reflect the branch you pulled from GitHub and save the file
- Go up one directory and run the ```BuildSalt.bat``` file. 

This file does the following:
- Copies ```C:\Python27``` to ```buildenv\bin```
- Deletes unused files from ```buildenv\bin```
- Runs ```makensis``` to build the installer
- Installer is placed in the ```installer``` directory
