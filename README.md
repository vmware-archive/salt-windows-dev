# salt-windows-dev 

## Description
This is a powershell script that sets up the development environment for salt.
All dependencies are installed.
The dependencies reside in two zip files found on http://docs.saltstack.com/downloads/windows-deps/
- salt32.zip
- salt64.zip

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
## Build Salt
Building salt has additional requirements not installed by this script. You'll need to install the NullSoft installer. That can be downloaded here: http://sourceforge.net/projects/nsis/files/NSIS%203%20Pre-release/3.0b1/nsis-3.0b1-setup.exe/download
### Build Steps
1. 
