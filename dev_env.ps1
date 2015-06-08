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

# Load parameters
param(
    [bool]$Silent = $False
)

Clear-Host
Write-Output "================================================================="
Write-Output ""
Write-Output "               Development Environment Installation"
Write-Output ""
Write-Output "               - Installs All Salt Dependencies"
Write-Output "               - Detects 32/64 bit Architectures"
Write-Output ""
Write-Output "               To run silently add -Silent $True"
Write-Output "               eg: dev_env.ps1 -Silent `$True"
Write-Output ""
Write-Output "================================================================="
Write-Output ""

#==============================================================================
# Get the Directory of actual script
#==============================================================================
$path = dir "$($myInvocation.MyCommand.Definition)"
$path = $path.DirectoryName

#==============================================================================
# Import Modules
#==============================================================================
Import-Module $path\Modules\download-module.psm1
Import-Module $path\Modules\get-settings.psm1
Import-Module $path\Modules\uac-module.psm1
Import-Module $path\Modules\zip-module.psm1

#==============================================================================
# Check for Elevated Privileges
#==============================================================================
if (!(Get-IsAdministrator))
{
    if (Get-IsUacEnabled)
    {
        
        # We are not running "as Administrator" - so relaunch as administrator
   
        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition

        # Specify the current working directory
        $newProcess.WorkingDirectory = "$path"
   
        # Indicate that the process should be elevated
        $newProcess.Verb = "runas";
   
        # Start the new process
        [System.Diagnostics.Process]::Start($newProcess);
   
        # Exit from the current, unelevated, process
        exit

    } else {
        throw "You must be administrator to run this script"
    }
}

#------------------------------------------------------------------------------
# Load Settings
#------------------------------------------------------------------------------
$ini = Get-Settings

#------------------------------------------------------------------------------
# Create Directories
#------------------------------------------------------------------------------
$p = New-Item $ini['Settings']['DownloadDir'] -ItemType Directory -Force
$p = New-Item $ini['Settings']['SaltDir'] -ItemType Directory -Force

#------------------------------------------------------------------------------
# Determine Architecture (32 or 64 bit) and assign variables
#------------------------------------------------------------------------------
If ([System.IntPtr]::Size -ne 4) {

    Write-Output "Detected 64bit Architecture..."

    $bitPaths    = "64bitPaths"
    $bitPrograms = "64bitPrograms"
    $bitFolder   = "64"
  
 } Else {

    Write-Output "Detected 32bit Architecture"

    $bitPaths    = "32bitPaths"
    $bitPrograms = "32bitPrograms"
    $bitFolder   = "32"

}

#------------------------------------------------------------------------------
# Check for installation of Git
#------------------------------------------------------------------------------
Write-Output " - Checking for Git installation . . ."
If ( Test-Path "$($ini[$bitPaths]['GitDir'])\bin\git.exe" ) {

    # Found Git, do nothing
    Write-Output " - Git Found . . ."

} Else {

    # Git not found, install
    Write-Output " - Git Not Found . . ."
    Write-Output " - Downloading $($ini['Prerequisites']['Git']) . . ."
    $file = "$($ini['Prerequisites']['Git'])"
    $url  = "$($ini['Settings']['SaltRepo'])/$file"
    $file = "$($ini['Settings']['DownloadDir'])\$file"
    DownloadFileWithProgress $url $file

    # Create the inf file to be passed to the Git executable
    Write-Host " - Creating inf . . ."
    Set-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "[Setup]"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "Lang=default"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "Dir=$($ini['64bitPaths']['GitDir'])"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "Group=Git"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "NoIcons=0"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "SetupType=default"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "Components=ext,ext\reg,ext\reg\shellhere,assoc,assoc_sh"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "Tasks="
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "PathOption=Cmd"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "SSHOption=OpenSSH"
    Add-Content -path "$($ini['Settings']['DownloadDir'])\git.inf" -value "CRLFOption=CRLFAlways"

    # Install Git
    Write-Output " - Installing $($ini['Prerequisites']['Git']) . . ."
    $file = "$($ini['Settings']['DownloadDir'])\$($ini['Prerequisites']['Git'])"
    $p = Start-Process $file -ArgumentList "/SILENT /LOADINF=$($ini['Settings']['DownloadDir'])\git.inf" -Wait -NoNewWindow -PassThru
}

#------------------------------------------------------------------------------
# Check for installation of NSIS
#------------------------------------------------------------------------------
Write-Output " - Checking for NSIS installation . . ."
If ( Test-Path "$($ini[$bitPaths]['NSISDir'])\NSIS.exe" ) {

    # Found NSIS, do nothing
    Write-Output " - NSIS Found . . ."

} Else {

    # NSIS not found, install
    Write-Output " - NSIS Not Found . . ."
    Write-Output " - Downloading $($ini['Prerequisites']['NSIS']) . . ."
    $file = "$($ini['Prerequisites']['NSIS'])"
    $url  = "$($ini['Settings']['SaltRepo'])/$file"
    $file = "$($ini['Settings']['DownloadDir'])\$file"
    DownloadFileWithProgress $url $file

    # Install NSIS
    Write-Output " - Installing $($ini['Prerequisites']['NSIS']) . . ."
    $file = "$($ini['Settings']['DownloadDir'])\$($ini['Prerequisites']['NSIS'])"
    $p    = Start-Process $file -ArgumentList '/S' -Wait -NoNewWindow -PassThru

}

#------------------------------------------------------------------------------
# Install Python
#------------------------------------------------------------------------------
Write-Output " - Downloading $($ini[$bitPrograms]['Python']) . . ."
$file = "$($ini[$bitPrograms]['Python'])"
$url  = "$($ini['Settings']['SaltRepo'])/$bitFolder/$file"
$file = "$($ini['Settings']['DownloadDir'])\$file"
DownloadFileWithProgress $url $file
    
Write-Output " - Installing $($ini[$bitPrograms]['Python']) . . ."
$file = "$($ini['Settings']['DownloadDir'])\$($ini[$bitPrograms]['Python'])"
$p    = Start-Process msiexec -ArgumentList "/i $file /qb ADDLOCAL=DefaultFeature,Extensions,PrependPath TARGETDIR=$($ini['Settings']['PythonDir'])" -Wait -NoNewWindow -PassThru

#------------------------------------------------------------------------------
# Update Environment Variables
#------------------------------------------------------------------------------
Write-Output " - Updating Environment Variables . . ."
$Path = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
If (!($Path.ToLower().Contains("$($ini['Settings']['ScriptsDir'])".ToLower()))) {
    $newPath  = "$($ini['Settings']['ScriptsDir']);$Path"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
    $env:Path = $newPath
}

#------------------------------------------------------------------------------
# pip (easy_install included in pip install file)
#------------------------------------------------------------------------------
Write-Output " - Downloading $($ini['CommonPrograms']['Pip']) . . ."
$file = "$($ini['CommonPrograms']['Pip'])"
$url  = "$($ini['Settings']['SaltRepo'])/$file"
$file = "$($ini['Settings']['DownloadDir'])\$file"
DownloadFileWithProgress $url $file

Write-Output " - Downloading $($ini['CommonPrograms']['Pip-Wheel']) . . ."
$file = "$($ini['CommonPrograms']['Pip-Wheel'])"
$url  = "$($ini['Settings']['SaltRepo'])/$file"
$file = "$($ini['Settings']['DownloadDir'])\$file"
DownloadFileWithProgress $url $file

Write-Output " - Downloading $($ini['CommonPrograms']['SetupTools']) . . ."
$file = "$($ini['CommonPrograms']['SetupTools'])"
$url  = "$($ini['Settings']['SaltRepo'])/$file"
$file = "$($ini['Settings']['DownloadDir'])\$file"
DownloadFileWithProgress $url $file

Write-Output " - Downloading $($ini['CommonPrograms']['Wheel']) . . ."
$file = "$($ini['CommonPrograms']['Wheel'])"
$url  = "$($ini['Settings']['SaltRepo'])/$file"
$file = "$($ini['Settings']['DownloadDir'])\$file"
DownloadFileWithProgress $url $file

# Use Python to install Pip
Write-Output " ----------------------------------------------------------------"
Write-Output " - Installing $($ini['CommonPrograms']['Pip']) . . ."
Write-Output " ----------------------------------------------------------------"
Write-Output "$($ini['Settings']['PythonDir'])\python $file --no-index --find-links=$($ini['Settings']['DownloadDir'])"
$file = "$($ini['Settings']['DownloadDir'])\$($ini['CommonPrograms']['Pip'])"
$p = Start-Process "$($ini['Settings']['PythonDir'])\python" -ArgumentList "$file --no-index --find-links=$($ini['Settings']['DownloadDir'])" -Wait -NoNewWindow -PassThru

#==============================================================================
# Install additional prerequisites using PIP
#==============================================================================
# Download first
#------------------------------------------------------------------------------
$arrInstalled = "Pip", "Pip-Wheel", "SetupTools", "Wheel", "Python"
Write-Output " ----------------------------------------------------------------"
Write-Output " - Downloading . . ."
Write-Output " ----------------------------------------------------------------"
ForEach( $key in $ini['CommonPrograms'].Keys ) {
    
    If ( $arrInstalled -notcontains $key ) {

        Write-Output "   - $key . . ."
        $file = "$($ini['CommonPrograms'][$key])"
        $url  = "$($ini['Settings']['SaltRepo'])/$file"
        $file = "$($ini['Settings']['DownloadDir'])\$file"
        DownloadFileWithProgress $url $file

    }

}

ForEach( $key in $ini[$bitPrograms].Keys ) {

    If ( $arrInstalled -notcontains $key ) {

        Write-Output "   - $key . . ."
        $file = "$($ini[$bitPrograms][$key])"
        $url  = "$($ini['Settings']['SaltRepo'])/$bitFolder/$file"
        $file = "$($ini['Settings']['DownloadDir'])\$file"
        DownloadFileWithProgress $url $file

    }

}

#------------------------------------------------------------------------------
# Install
#------------------------------------------------------------------------------
Write-Output " ----------------------------------------------------------------"
Write-Output " - Installing . . ."
Write-Output " ----------------------------------------------------------------"

ForEach( $key in $ini['CommonPrograms'].Keys ) {

    If ( $arrInstalled -notcontains $key ) {

        Write-Output " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
        Write-Output "   - $key . . ."
        
        Write-Output " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
        $file = "$($ini['Settings']['DownloadDir'])\$($ini['CommonPrograms'][$key])"
        $file = dir "$($file)"
        If ( $file.Extension -eq ".exe" ) {

            $p = Start-Process "$($ini['Settings']['ScriptsDir'])\easy_install" -ArgumentList "-Z $file" -Wait -NoNewWindow -PassThru

        } else {

            $p = Start-Process "$($ini['Settings']['ScriptsDir'])\pip" -ArgumentList "install --no-index --find-links=$($ini['Settings']['DownloadDir']) $file " -Wait -NoNewWindow -PassThru

        }

    }

}

ForEach( $key in $ini[$bitPrograms].Keys ) {

    If ( $arrInstalled -notcontains $key ) {

        Write-Output " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
        Write-Output "   - $key . . ."
        Write-Output " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
        $file = "$($ini['Settings']['DownloadDir'])\$($ini[$bitPrograms][$key])"
        $file = dir "$($file)"
        If ( $file.Extension -eq ".exe" ) {

            $p = Start-Process "$($ini['Settings']['ScriptsDir'])\easy_install" -ArgumentList "-Z $file" -Wait -NoNewWindow -PassThru

        } else {
    
            $p = Start-Process "$($ini['Settings']['ScriptsDir'])\pip" -ArgumentList "install --no-index --find-links=$($ini['Settings']['DownloadDir']) $file " -Wait -NoNewWindow -PassThru
        
        }
    
    }

}

#------------------------------------------------------------------------------
# Script complete
#------------------------------------------------------------------------------
Write-Output "================================================================="
Write-Output "Salt Stack Dev Environment Script Complete"
Write-Output "================================================================="
Write-Output ""

If ( -Not $Silent ) {
    Write-Output "Press any key to continue ..."
    $p = $HOST.UI.RawUI.Flushinputbuffer()
    $p = $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#------------------------------------------------------------------------------
# Remove the temperary download directory
#------------------------------------------------------------------------------
Write-Output " ----------------------------------------------------------------"
Write-Output " - Cleaning up downloaded files"
Write-Output " ----------------------------------------------------------------"
Write-Output ""
Remove-Item $($ini['Settings']['DownloadDir']) -Force -Recurse