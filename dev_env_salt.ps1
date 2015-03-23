#==============================================================================
# You may need to change the execution policy in order to run this script
# Run the following in powershell:
#
# Set-ExecutionPolicy RemoteSigned
#
#==============================================================================
#
#          FILE: dev_env.ps1
#
#   DESCRIPTION: Development Environment Installation for Windows
#
#          BUGS: https://github.com/saltstack/salt-windows-bootstrap/issues
#
#     COPYRIGHT: (c) 2012-2015 by the SaltStack Team, see AUTHORS.rst for more
#                details.
#
#       LICENSE: Apache 2.0
#  ORGANIZATION: SaltStack (saltstack.org)
#       CREATED: 03/15/2015
#==============================================================================

Clear-Host
Write-Output "================================================================="
Write-Output ""
Write-Output "               Development Environment Installation"
Write-Output ""
Write-Output "               - Installs Salt"
Write-Output "               - Detects 32/64 bit Architecture"
Write-Output "               - Detects installation of Git"
Write-Output ""
Write-Output "================================================================="
Write-Output ""

#==============================================================================
# Declare Variables
#==============================================================================
# Path Variables
#------------------------------------------------------------------------------
$strDownloadDir     = "$env:Temp\DevSalt"
$strSaltDir         = "C:\Salt-Dev"
$strWindowsRepo     = "http://docs.saltstack.com/downloads/windows-deps"

#------------------------------------------------------------------------------
# Create Directories
#------------------------------------------------------------------------------
$p = New-Item $strDownloadDir -ItemType Directory -Force
$p = New-Item $strSaltDir -ItemType Directory -Force

#------------------------------------------------------------------------------
# Installation file Variables
#------------------------------------------------------------------------------
$strGit         = "Git-1.9.5-preview20141217.exe"
$strSaltClone   = "https://github.com/saltstack/salt"
$strSaltVersion = "2015.2"

#------------------------------------------------------------------------------
# Determine Architecture (32 or 64 bit) and assign variables
#------------------------------------------------------------------------------
If (((Get-WMIObject Win32_OperatingSystem).OSArchitecture).Contains("64")) {

    Write-Output "Detected 64bit Architecture..."
    $strGitDir      = "C:\Program Files (x86)\Git"

} Else {

    Write-Output "Detected 32bit Architecture..."
    $strGitDir      = "C:\Program Files\Git"
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
$check = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
         Select-Object DisplayName, DisplayVersion |
         Where-Object {$_.DisplayName -like 'Git*'}
If ($check[0]) {

    # Found Git, do nothing

} Else {

    # Git not found, install
    Write-Output "Downloading $strArchiveFile . . ."
    $file = $strGit
    $url = "$strWindowsRepo\$file"
    $file = "$strDownloadDir\$file"
    DownloadFileWithProgress $url $file

    # Create the inf file to be passed to the Git executable
    Write-Host "- creating inf"
    Set-Content -path $strDownloadDir\git.inf -value "[Setup]"
    Add-Content -path $strDownloadDir\git.inf -value "Lang=default"
    Add-Content -path $strDownloadDir\git.inf -value "Dir=C:\Program Files (x86)\Git"
    Add-Content -path $strDownloadDir\git.inf -value "Group=Git"
    Add-Content -path $strDownloadDir\git.inf -value "NoIcons=0"
    Add-Content -path $strDownloadDir\git.inf -value "SetupType=default"
    Add-Content -path $strDownloadDir\git.inf -value "Components=ext,ext\cheetah,assoc,assoc_sh"
    Add-Content -path $strDownloadDir\git.inf -value "Tasks="
    Add-Content -path $strDownloadDir\git.inf -value "PathOption=Cmd"
    Add-Content -path $strDownloadDir\git.inf -value "SSHOption=OpenSSH"
    Add-Content -path $strDownloadDir\git.inf -value "CRLFOption=CRLFAlways"

    # Install Git
    Write-Output " - Installing $strGit . . ."
    $file = "$strDownloadDir\$strGit"
    $p = Start-Process $file -ArgumentList '/SILENT /LOADINF="$strDownloadDir\git.inf"' -Wait -NoNewWindow -PassThru

}

#------------------------------------------------------------------------------
#
# Update Environment Variables
#------------------------------------------------------------------------------
Write-Output " - Updating Environment Variables . . ."
$Path=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
If (!($Path.ToLower().Contains("$strGitDir\bin".ToLower()))) {
    $newPath="$strGitDir\bin;$Path"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

#------------------------------------------------------------------------------
# Clone Salt from Github
#------------------------------------------------------------------------------
Write-Output " - Cloning salt from $strSaltClone"
Set-Location -Path "$strSaltDir"
$p = Start-Process Git -ArgumentList "clone $strSaltClone" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# Select the branch defined in $strSaltVersion
#------------------------------------------------------------------------------
Set-Location -Path "$strSaltDir\salt"
$p = Start-Process Git -ArgumentList "fetch --all" -Wait -NoNewWindow -PassThru
$p = Start-Process Git -ArgumentList "checkout $strSaltVersion" -Wait -NoNewWindow -PassThru
$p = Start-Process Git -ArgumentList "clean -fxd" -Wait -NoNewWindow -PassThru
$p = Start-Process Git -ArgumentList "reset --hard HEAD" -Wait -NoNewWindow -PassThru
$p = Start-Process Python -ArgumentList "setup.py install --force" -Wait -NoNewWindow -PassThru

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
$p = Start-Process Git -ArgumentList "status" -Wait -NoNewWindow -PassThru
Write-Output " ----------------------------------------------------------------"
Write-Output ""

#------------------------------------------------------------------------------
# Script complete
#------------------------------------------------------------------------------
Write-Output "================================================================="
Write-Output "Salt Stack Dev Environment Script Complete"
Write-Output "================================================================="
Write-Output ""
Write-Output "Press any key to continue ..."
$p = $HOST.UI.RawUI.Flushinputbuffer()
$p = $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
