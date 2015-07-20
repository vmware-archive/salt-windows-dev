# salt-windows-dev 

## Description
This is a powershell script that sets up the development environment for salt. In the development environment you can run salt from the source code to develop and test new modules as well as test bug fixes and issues. You can also build a new windows installation based on the source code.
The dependencies reside on http://docs.saltstack.com/downloads/windows-deps/

## Usage
If you have network connectivity you can run this script on the machine you wish to set up with the development environment. If you need to set this up on a closed network, you can download all the dependencies individually and then point to them by editing the ```get-settings.psm1``` file. Just change the "SaltRepo" hash table value in the script to point to the location of the two zip files. This can be a network share or a local directory. eg:
```
$Settings = @{
    "SaltRepo"    = "\\Your\Location\Here"
    ...
}
```
If you put this script in the same directory with your dependencies folder (C:\Some\Path\Dependencies) this value can be "Convert-Path .\Dependencies", without the quotes. eg:
```
$Settings = @{
    "SaltRepo"    = Convert-Path .\Dependencies
    ...
}
```
## Develop Salt
After running this script, pull the branch of salt you want to work on from github. Open a command prompt and go into the salt directory. Run the following command:
```
pip install -e .
```
You'll also need to copy the windows specific configuration files to ```c:\salt```. These files can be found in your cloned salt repo in ```salt\pkg\windows\buildenv```. Copy the contents of this directory to ```c:\salt```.

This will allow you to work off your source code. To start a salt-minion in debug, just type salt-minion -l debug. When you edit your code, just restart your minion to test.

## Build a Windows Installer for Salt
To build a Windows Installer for salt you need to work out of a clean python installation. If you've been working in a development environment for salt, ie. you ran the ```pip install -e .``` command you'll need to uninstall Python 2.7 and then remove the ```C:\Python27``` directory. Run the ```dev-env.ps1``` script again to reinstall the Salt Development environment. Then go into the salt directory and run the following command:
```
python setup.py install
```
This will install salt into your Python27 directory.

Navigate to the ```.\salt\pkg\windows``` directory in your salt repo. Everything you need to build your windows installer is in this directory.

The ```buildenv``` folder contains files that will be installed along with salt. The ```installer``` folder contains the files needed to create the .exe. The root of this directory contains the scripts used to build the Windows installer.

Run the ```BuildSalt.bat``` script with the version or name of the build you wish to build. eg:
```
BuildSalt.bat 2015.5-TestBuild
```
If you need to have spaces in the build name wrap them in quotes. eg:
```
BuildSalt.bat "My Test Build"
```
This script does the following:
- Removes ```buildenv\bin``` if it exists
- Copies the contents of ```C:\Python27``` to ```buildenv\bin```
- Edits the pip and easy_install binaries to be portable
- Deletes unneeded files from ```buildenv\bin```  (.pyc, .chm)
- Removes unused modules and documentation (doc, share, tcl, lib-tk, test, etc...)
- Runs ```makensis``` to build the installer

The installer is named something like ```Salt-Minion-<passed version>-Setup.exe``` and is placed in the ```installer``` directory. This is what you will use to install your build of Salt.

