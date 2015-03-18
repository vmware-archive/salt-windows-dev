#==============================================================================
# You may need to change the execution policy in order to run this script
# Run the following in powershell:
#
# Set-ExecutionPolicy RemoteSigned
#
#==============================================================================
#
#          FILE: Bootstrap.ps1
#
#   DESCRIPTION: Bootstrap salt installation for 64bit windows distributions
#
#          BUGS: https://github.com/saltstack/salt-windows-bootstrap/issues
#
#     COPYRIGHT: (c) 2012-2015 by the SaltStack Team, see AUTHORS.rst for more
#                details.
#
#       LICENSE: Apache 2.0
#  ORGANIZATION: SaltStack (saltstack.org)
#       CREATED: 02/09/2015
#==============================================================================

Clear-Host
Write-Output "==========================================="
Write-Output ""
Write-Output " Windows Development Environment Bootstrap"
Write-Output ""
Write-Output " - Installs All Salt Dependencies"
Write-Output " - Detects 32/64 bit Architectures"
Write-Output ""
Write-Output "==========================================="
Write-Output ""

#==============================================================================
# Declare Variables
#==============================================================================
# Path Variables
#------------------------------------------------------------------------------
$strDownloadDir     = "$env:Temp\DevSalt"
$strSaltDir         = "C:\salt"
$strWindowsRepo     = "http://docs.saltstack.com/downloads/windows-deps"
$strPythonDir       = "C:\Python27"
$strScriptsDir      = "$strPythonDir\Scripts"

#------------------------------------------------------------------------------
# Create Directories
#------------------------------------------------------------------------------
$p = New-Item $strDownloadDir -ItemType Directory -Force
$p = New-Item $strSaltDir -ItemType Directory -Force

#------------------------------------------------------------------------------
# Installation file Variables
#------------------------------------------------------------------------------
$strPip         = "get-pip.py"
$strJinja       = "Jinja2-2.7.3-py27-none-any.whl"
$strRequests    = "requests-2.5.3-py2.py3-none-any.whl"
$strVCForPython = "VCForPython27.msi"
$strWMI         = "WMI-1.4.9-py2-none-any.whl"
$strSalt        = "salt-2014.7.2.tar.gz"

#------------------------------------------------------------------------------
# Determine Architecture (32 or 64 bit) and assign variables
#------------------------------------------------------------------------------
If (((Get-WMIObject Win32_OperatingSystem).OSArchitecture).Contains("64")) {

    Write-Output "Detected 64bit Architecture..."

    $strArchiveFile = "Salt64.zip"

    $strM2Crypto    = "64\M2Crypto-0.21.1.win-amd64-py2.7.exe"
    $strMarkupSafe  = "64\MarkupSafe-0.23-cp27-none-win_amd64.whl"
    $strMsgPack     = "64\msgpack_python-0.4.5-cp27-none-win_amd64.whl"
    $strPSUtil      = "64\psutil-2.2.1-cp27-none-win_amd64.whl"
    $strPyCrypto    = "64\pycrypto-2.6.win-amd64-py2.7.exe"
    $strPython      = "64\python-2.7.8.amd64.msi"
    $strPyWin       = "64\pywin32-219.win-amd64-py2.7.exe"
    $strPyYAML      = "64\PyYAML-3.11-cp27-none-win_amd64.whl"
    $strPyZMQ       = "64\pyzmq-14.5.0-cp27-none-win_amd64.whl"
    $strVCRedist    = "64\vcredist_x64.exe"
    $strVCRedistMFC = "64\vcredist_x64_mfc_update.exe"
    $strOpenSSL     = "64\Win64OpenSSL_Light-1_0_1L.exe"

 } Else {

    Write-Output "Detected 32bit Architecture"

    $strArchiveFile = "Salt32.zip"

    $strM2Crypto    = "32\M2Crypto-0.21.1.win32-py2.7.exe"
    $strMarkupSafe  = "32\MarkupSafe-0.23-cp27-none-win32.whl"
    $strMsgPack     = "32\msgpack_python-0.4.5-cp27-none-win32.whl"
    $strPSUtil      = "32\psutil-2.2.1-cp27-none-win32.whl"
    $strPyCrypto    = "32\pycrypto-2.6.win32-py2.7.exe"
    $strPython      = "32\python-2.7.8.msi"
    $strPyWin       = "32\pywin32-219.win32-py2.7.exe"
    $strPyYAML      = "32\PyYAML-3.11-cp27-none-win32.whl"
    $strPyZMQ       = "32\pyzmq-14.5.0-cp27-none-win32.whl"
    $strVCRedist    = "32\vcredist_x86.exe"
    $strVCRedistMFC = "32\vcredist_x86_mfc_update.exe"
    $strOpenSSL     = "32\Win32OpenSSL_Light-1_0_1L.exe"

}

#==============================================================================
# Define Functions
#==============================================================================
Function DownloadFileWithProgress {

    # Code for this function borrowed from http://poshcode.org/2461
    # Thanks Crazy Dave

    # This function downloads the passed file and shows a progress bar
    # It receives two parameters:
    #    $url - the file source
    #    $localfile - the file destination on the local machine

    param(
        [Parameter(Mandatory=$true)]
        [String] $url,
        [Parameter(Mandatory=$false)]
        [String] $localFile = (Join-Path $pwd.Path $url.SubString($url.LastIndexOf('/'))) 
    )

    begin {
        $client = New-Object System.Net.WebClient
        $Global:downloadComplete = $false
        $eventDataComplete = Register-ObjectEvent $client DownloadFileCompleted `
            -SourceIdentifier WebClient.DownloadFileComplete `
            -Action {$Global:downloadComplete = $true}
        $eventDataProgress = Register-ObjectEvent $client DownloadProgressChanged `
            -SourceIdentifier WebClient.DownloadProgressChanged `
            -Action { $Global:DPCEventArgs = $EventArgs }
    }
    process {
        Write-Progress -Activity 'Downloading file' -Status $url
        $client.DownloadFileAsync($url, $localFile)

        while (!($Global:downloadComplete)) {
            $pc = $Global:DPCEventArgs.ProgressPercentage
            if ($pc -ne $null) {
                Write-Progress -Activity 'Downloading file' -Status $url -PercentComplete $pc
            }
        }
        Write-Progress -Activity 'Downloading file' -Status $url -Complete
    }

    end {
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
        $client.Dispose()
        $Global:downloadComplete = $null
        $Global:DPCEventArgs = $null
        Remove-Variable client
        Remove-Variable eventDataComplete
        Remove-Variable eventDataProgress
        [GC]::Collect()
    }
}

Function Expand-ZipFile($zipfile, $destination) {

    # This function unzips a zip file
    # Code obtained from:
    # http://www.howtogeek.com/tips/how-to-extract-zip-files-using-powershell/

    # Create a new directory if it doesn't exist
    If (!(Test-Path -Path $destination)) {
        $p = New-Item -ItemType directory -Path $destination
    }

    # Define Objects
    $objShell = New-Object -Com Shell.Application

    # Open the zip file
    $objZip = $objShell.NameSpace($zipfile)

    # Unzip each item in the zip file
    ForEach($item in $objZip.Items()) {
        $objShell.Namespace($destination).CopyHere($item, 0x14)
    }
}

#==============================================================================
# Download Dependencies File
#==============================================================================
Write-Output "Downloading $strArchiveFile . . ."
$file = $strArchiveFile
$url = "$strWindowsRepo\$file"
$file = "$strDownloadDir\$file"
If (!(Test-Path $file)) {
    DownloadFileWithProgress $url $file
}

#==============================================================================
# Unzip Dependencies File
#==============================================================================
Write-Output "Unzipping $strArchiveFile . . ."
Expand-ZipFile $file $strDownloadDir

#==============================================================================
# Install Dependencies
#==============================================================================
Write-Output "Installing Dependencies . . ."

#------------------------------------------------------------------------------
# Install Python
#------------------------------------------------------------------------------
Write-Output " - Installing $strPython . . ."
$file = "$strDownloadDir\$strPython"
$p = Start-Process msiexec -ArgumentList "/i $file /qb ADDLOCAL=ALL TARGETDIR=$strPythonDir" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# Update Environment Variables
#------------------------------------------------------------------------------
Write-Output " - Updating Environment Variables . . ."
$Path=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
If (!($Path.ToLower().Contains("$strPythonDir\Scripts".ToLower()))) {
    $newPath="$strPythonDir\Scripts;$Path"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

#------------------------------------------------------------------------------
# VC++ Compiler for Python
#------------------------------------------------------------------------------
Write-Output " - Installing $strVCForPython . . ."
$file = "$strDownloadDir\$strVCForPython"
$p = Start-Process msiexec -ArgumentList "/i $file /qb" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# Visual C++ 2008 Redistributable
#------------------------------------------------------------------------------
Write-Output " - Installing $strVCRedist . . ."
$file = "$strDownloadDir\$strVCRedist"
$p = Start-Process $file -ArgumentList "/q" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# Visual C++ 2008 Redistrubutable MFC Update
#------------------------------------------------------------------------------
Write-Output " - Installing $strVCRedistMFC . . ."
$file = "$strDownloadDir\$strVCRedistMFC"
$p = Start-Process $file -ArgumentList "/q" -Wait -NoNewWindow -PassThru

# Copy the libary to the Python directory (for compiling)
#$file = "C:\Windows\WinSxS\amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_9.0.30729.6161_none_08e61857a83bc251\msvcp90.dll"
#Copy-Item $file C:\Python27 -Force

#------------------------------------------------------------------------------
# OpenSSL
#------------------------------------------------------------------------------
Write-Output " - Installing $strOpenSSL . . ."
$file = "$strDownloadDir\$strOpenSSL"
$p = Start-Process $file -ArgumentList "/silent" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# pip (easy_install included in pip install file)
#------------------------------------------------------------------------------
Write-Output " - Installing $strPip . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strPip"
$p = Start-Process "$strPythonDir\python" -ArgumentList "$file --no-index --find-links=$strDownloadDir" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

#==============================================================================
# Install Executables using Easy_Install
#==============================================================================

#------------------------------------------------------------------------------
# M2Crypto
#------------------------------------------------------------------------------
Write-Output " - Installing $strM2Crypto . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strM2Crypto"
$p = Start-Process "$strScriptsDir\easy_install" -ArgumentList $file -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

#------------------------------------------------------------------------------
# PyCrypto
#------------------------------------------------------------------------------
Write-Output " - Installing $strPyCrypto . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strPyCrypto"
$p = Start-Process "$strScriptsDir\easy_install" -ArgumentList $file -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

#------------------------------------------------------------------------------
# PyWin32
#------------------------------------------------------------------------------
Write-Output " - Installing $strPyWin . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strPyWin"
$p = Start-Process "$strScriptsDir\easy_install" -ArgumentList $file -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

#==============================================================================
# Install additional prerequisites using PIP
#==============================================================================

Write-Output " - Installing $strMarkupSafe . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strMarkupSafe"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

Write-Output " - Installing $strJinja . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strJinja"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

Write-Output " - Installing $strMsgPack . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strMsgPack"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru

Write-Output " --------------------------------"
Write-Output " - Installing $strPSUtil . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strPSUtil"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

Write-Output " - Installing $strPyYAML . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strPyYAML"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

Write-Output " - Installing $strPyZMQ . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strPyZMQ"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

Write-Output " - Installing $strWMI . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strWMI"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

Write-Output " - Installing $strRequests . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strRequests"
$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

Write-Output " - Installing $strSalt . . ."
Write-Output " --------------------------------"
$file = "$strDownloadDir\$strSalt"
#$p = Start-Process "$strScriptsDir\pip" -ArgumentList "install $file" -Wait -NoNewWindow -PassThru
Write-Output " --------------------------------"

#------------------------------------------------------------------------------
# Copy Salt Configuration Files
#------------------------------------------------------------------------------
Write-Output " - Copying Salt configuration files . . ."
Write-Output " --------------------------------"
Write-Output ""
$strConfigFiles = "$strDownloadDir\buildenv\*"
# Copy-Item $strConfigFiles $strSaltDir -recurse
Write-Output " --------------------------------"

#------------------------------------------------------------------------------
# Remove the temperary download directory
#------------------------------------------------------------------------------
Write-Output " - Cleaning up downloaded files"
Write-Output " --------------------------------"
Write-Output ""
Remove-Item $strDownloadDir -Force -Recurse

#------------------------------------------------------------------------------
# Script complete
#------------------------------------------------------------------------------
Write-Output "==========================================="
Write-Output "Salt Stack Dev Environment Script Complete"
Write-Output "==========================================="
Write-Output ""
Write-Output "Press any key to continue ..."
$p = $HOST.UI.RawUI.Flushinputbuffer()
$p = $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
