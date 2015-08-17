#==============================================================================
# You may need to change the execution policy in order to run this script
# Run the following in powershell:
#
# Set-ExecutionPolicy RemoteSigned
#
#==============================================================================
#
#          FILE: dev_env_salt.ps1
#
#   DESCRIPTION: Installs Salt in the Development Environment for Windows
#
#          BUGS: https://github.com/saltstack/salt-windows-dev/issues
#
#     COPYRIGHT: (c) 2012-2015 by the SaltStack Team, see AUTHORS.rst for more
#                details.
#
#       LICENSE: Apache 2.0
#  ORGANIZATION: SaltStack (saltstack.org)
#       CREATED: 03/23/2015
#==============================================================================

# Load parameters
param(
    [bool]$Silent = $False,
    [string]$Version = "2015.5"
)

Clear-Host
Write-Output "================================================================="
Write-Output ""
Write-Output "            Salt Development Environment Installation"
Write-Output ""
Write-Output "               - Installs Salt"
Write-Output "               - Detects 32/64 bit Architecture"
Write-Output "               - Detects installation of Git"
Write-Output "               - Detects installation of Nullsoft Installer"
Write-Output ""
Write-Output "            To run silently add -Silent `$True"
Write-Output "            eg: dev_env_salt.ps1 -Silent `$True"
Write-Output ""
Write-Output "            To specify a version add -Version '2015.5'"
Write-Output "            eg: dev_env_salt.ps1 -Version '2015.5'"
Write-Output ""
Write-Output "================================================================="
Write-Output ""

#==============================================================================
# Declare Variables
#==============================================================================
# Source and Version Variables
#------------------------------------------------------------------------------
$strSaltClone   = "https://github.com/saltstack/salt"
$strSaltVersion = $Version

# Path Variables
#------------------------------------------------------------------------------
$strDownloadDir     = "$env:Temp\DevSalt"
$strSaltDir         = "C:\Salt-Dev"
$strWindowsRepo     = "http://repo.saltstack.com/windows/dependencies/"
$strPythonDir       = "C:\Python27"

#------------------------------------------------------------------------------
# Create Directories
#------------------------------------------------------------------------------
$p = New-Item $strDownloadDir -ItemType Directory -Force

#------------------------------------------------------------------------------
# Check to see if the Salt Directory already exists
# - Prompt to continue if it does
# - Delete the directory if silent
# - Create the directory if it doesn't
#------------------------------------------------------------------------------
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Description."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Description."
$cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Description."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $cancel)

If ( Test-Path -Path $strSaltDir ) {

    If ( $Silent ) {

        # Remove the directory
        Write-Output " - Removing the contents of $strSaltDir"
        Remove-Item $strSaltDir\* -Force -Recurse

    } Else {

        # Prompt to continue
        Write-Output ""
        Write-Output "-------------------------------------------------------------"
        Write-Host " Existing Dev Directory Found" -ForegroundColor Yellow
        Write-Output "-------------------------------------------------------------"
        Write-Output ""
        Write-Host " The following directory exists:" -ForegroundColor Yellow
        Write-Host " $strSaltDir" -ForegroundColor Yellow
        Write-Output ""
        Write-Output "-------------------------------------------------------------"
        Write-Host " Would you like to delete the contents of this directory?" -ForegroundColor Yellow
        Write-Output "-------------------------------------------------------------"
        Write-Output ""
        $result = $host.ui.PromptForChoice("", "", $options, 0)
        Write-Output ""
        Switch ($result) {

            # Selected Yes, Remove folder contents
            0 {
                Write-Output " - Removing the contents of $strSaltDir"
                Remove-Item $strSaltDir\* -Force -Recurse
                Break
            }

            # Selected No, continue with no change
            1 {
                Write-Output " - Contents NOT Deleted"
                Break
            }

            # Selected Cancel, end the script
            2{ Exit }
        }
    }

} Else {

    $p = New-Item $strSaltDir -ItemType Directory -Force

}

#------------------------------------------------------------------------------
# Installation file Variables
#------------------------------------------------------------------------------
$strGit         = "Git-1.9.5-preview20141217.exe"
$strNSIS        = "nsis-3.0b1-setup.exe"

#------------------------------------------------------------------------------
# Determine Architecture (32 or 64 bit) and assign variables
#------------------------------------------------------------------------------
If (((Get-WMIObject Win32_OperatingSystem).OSArchitecture).Contains("64")) {

    Write-Output " - Detected 64bit Architecture..."
    $strGitDir      = "C:\Program Files (x86)\Git"
    $strNSISDir     = "C:\Program Files (x86)\NSIS"

} Else {

    Write-Output " - Detected 32bit Architecture..."
    $strGitDir      = "C:\Program Files\Git"
    $strNSISDir     = "C:\Program Files\NSIS"

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

#==============================================================================
# Check for installation of Git
#==============================================================================
Write-Output " - Checking for Git installation . . ."
If ( Test-Path $strGitDir\bin\git.exe ) {

    # Found Git, do nothing
    Write-Output " - Git Found"

} Else {

    # Git not found, install
    Write-Output " - Git Not Found"
    Write-Output " - Downloading $strGit . . ."
    $file = $strGit
    $url = "$strWindowsRepo\$file"
    $file = "$strDownloadDir\$file"
    DownloadFileWithProgress $url $file

    # Create the inf file to be passed to the Git executable
    Write-Host " - Creating inf"
    Set-Content -path $strDownloadDir\git.inf -value "[Setup]"
    Add-Content -path $strDownloadDir\git.inf -value "Lang=default"
    Add-Content -path $strDownloadDir\git.inf -value "Dir=$strGitDir"
    Add-Content -path $strDownloadDir\git.inf -value "Group=Git"
    Add-Content -path $strDownloadDir\git.inf -value "NoIcons=0"
    Add-Content -path $strDownloadDir\git.inf -value "SetupType=default"
    Add-Content -path $strDownloadDir\git.inf -value "Components=ext,ext\reg,ext\reg\shellhere,assoc,assoc_sh"
    Add-Content -path $strDownloadDir\git.inf -value "Tasks="
    Add-Content -path $strDownloadDir\git.inf -value "PathOption=Cmd"
    Add-Content -path $strDownloadDir\git.inf -value "SSHOption=OpenSSH"
    Add-Content -path $strDownloadDir\git.inf -value "CRLFOption=CRLFAlways"

    # Install Git
    Write-Output " - Installing $strGit . . ."
    $file = "$strDownloadDir\$strGit"
    $p = Start-Process $file -ArgumentList "/SILENT /LOADINF=$strDownloadDir\git.inf" -Wait -NoNewWindow -PassThru

}

#==============================================================================
# Check for installation of NSIS
#==============================================================================
Write-Output " - Checking for NSIS installation . . ."
If ( Test-Path $strNSISDir\NSIS.exe ) {

    # Found NSIS, do nothing
    Write-Output " - NSIS Found"

} Else {

    # NSIS not found, install
    Write-Output " - NSIS Not Found"
    Write-Output " - Downloading $strNSIS . . ."
    $file = $strNSIS
    $url = "$strWindowsRepo\$file"
    $file = "$strDownloadDir\$file"
    DownloadFileWithProgress $url $file

    # Install NSIS
    Write-Output " - Installing $strNSIS . . ."
    $file = "$strDownloadDir\$strNSIS"
    $p = Start-Process $file -ArgumentList '/S' -Wait -NoNewWindow -PassThru

}

#------------------------------------------------------------------------------
# Clone Salt from Github
#------------------------------------------------------------------------------
Write-Output " - Cloning salt from $strSaltClone"
Write-Output " - Target Directory: $strSaltDir"
Write-Output ""
Set-Location -Path "$strSaltDir"
$p = Start-Process $strGitDir\bin\git.exe -ArgumentList "clone $strSaltClone" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# Select the branch defined in $strSaltVersion
#------------------------------------------------------------------------------
Set-Location -Path "$strSaltDir\salt"
$p = Start-Process $strGitDir\bin\git.exe -ArgumentList "fetch --all" -Wait -NoNewWindow -PassThru
$p = Start-Process $strGitDir\bin\git.exe -ArgumentList "checkout $strSaltVersion" -Wait -NoNewWindow -PassThru
$p = Start-Process $strGitDir\bin\git.exe -ArgumentList "clean -fxd" -Wait -NoNewWindow -PassThru
$p = Start-Process $strGitDir\bin\git.exe -ArgumentList "reset --hard HEAD" -Wait -NoNewWindow -PassThru
$p = Start-Process $strPythonDir\Python -ArgumentList "setup.py install --force" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# Remove the temperary download directory
#------------------------------------------------------------------------------
Write-Output " ----------------------------------------------------------------"
Write-Output " - Cleaning up downloaded files"
Write-Output " ----------------------------------------------------------------"
Write-Output ""
Remove-Item $strDownloadDir -Force -Recurse

#------------------------------------------------------------------------------
# Display Branch
#------------------------------------------------------------------------------
Write-Output " ----------------------------------------------------------------"
$p = Start-Process $strGitDir\bin\git.exe -ArgumentList "status" -Wait -NoNewWindow -PassThru
Write-Output " ----------------------------------------------------------------"
Write-Output ""

#------------------------------------------------------------------------------
# Script complete
#------------------------------------------------------------------------------
Write-Output "================================================================="
Write-Output "Salt Stack Dev Environment Script Complete"
Write-Output " - Salt Version:     $strSaltVersion"
Write-Output " - Target Directory: $strSaltDir"
Write-Output "================================================================="
Write-Output ""

If ( -Not $Silent ) {
    Write-Output "Press any key to continue ..."
    $p = $HOST.UI.RawUI.Flushinputbuffer()
    $p = $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
