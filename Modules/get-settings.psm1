Function Get-Settings {

    [CmdletBinding()]
    Param()

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"} 

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Loading Settings"

        $ini = @{}

        # Location where the files are kept
        $Settings = @{
            "SaltRepo"    = "http://docs.saltstack.com/downloads/windows-deps"
            "SaltDir"     = "C:\salt"
            "PythonDir"   = "C:\Python27"
            "ScriptsDir"  = "C:\Python27\Scripts"
            "DownloadDir" = "$env:Temp\DevSalt"
            }
        $ini.Add("Settings", $Settings)

        # Prerequisite software
        $Prerequisites = @{
            "Git"  = "Git-1.9.5-preview20141217.exe"
            "NSIS" = "nsis-3.0b1-setup.exe"
        }
        $ini.Add("Prerequisites", $Prerequisites)

        # Location of programs on 64 bit Windows
        $64bitPaths = @{
            "GitDir"  = "C:\Program Files (x86)\Git"
            "NSISDir" = "C:\Program Files (x86)\NSIS"
        }
        $ini.Add("64bitPaths", $64bitPaths)

        # Location of programs on 32 bit Windows
        $32bitPaths = @{
            "GitDir"  = "C:\Program Files\Git"
            "NSISDir" = "C:\Program Files\NSIS"
        }
        $ini.Add("32bitPaths", $32bitPaths)

        # CPU Architecture Independent Software
        $CommonPrograms = @{
            "Certifi"    = "certifi-2015.04.28-py2.py3-none-any.whl"
            "GnuGPG"     = "python-gnupg-0.3.7.tar.gz"
            "Jinja"      = "Jinja2-2.7.3-py27-none-any.whl"
            "MarkupSafe" = "MarkupSafe-0.23.tar.gz"
            "MsgPack"    = "msgpack-python-0.4.6.tar.gz"
            "Pip"        = "get-pip-7.0.3.py"
            "Pip-Wheel"  = "pip-7.0.3-py2.py3-none-any.whl"
            "PyYAML"     = "PyYAML-3.11.tar.gz"
            "Requests"   = "requests-2.5.3-py2.py3-none-any.whl"
            "SetupTools" = "setuptools-17.0-py2.py3-none-any.whl"
            "Wheel"      = "wheel-0.24.0-py2.py3-none-any.whl"
            "WMI"        = "WMI-1.4.9-py2-none-any.whl"
        }
        $ini.Add("CommonPrograms", $CommonPrograms)

        # Filenames for 64 bit Windows
        $64bitPrograms = @{
            "M2Crypto"   = "M2Crypto-0.21.1.win-amd64-py2.7.exe"
            "PSUtil"     = "psutil-2.2.1-cp27-none-win_amd64.whl"
            "PyCrypto"   = "pycrypto-2.6.1-cp27-none-win_amd64.whl"
            "PyZMQ"      = "pyzmq-14.6.0-cp27-none-win_amd64.whl"
            "Python"     = "python-2.7.8.amd64.msi"
            "PyWin"      = "pypiwin32-219-cp27-none-win_amd64.whl"
        }
        $ini.Add("64bitPrograms", $64bitPrograms)

        # Filenames for 32 bit Windows
        $32bitPrograms = @{
            "M2Crypto"   = "M2Crypto-0.21.1.win32-py2.7.exe"
            "Python"     = "python-2.7.8.msi"
            "PSUtil"     = "psutil-2.2.1-cp27-none-win32.whl"
            "PyCrypto"   = "pycrypto-2.6.1-cp27-none-win32.whl"
            "PyZMQ"      = "pyzmq-14.6.0-cp27-none-win32.whl"
            "PyWin"      = "pypiwin32-219-cp27-none-win32.whl"
        }
        $ini.Add("32bitPrograms", $32bitPrograms)

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Loading Settings"
        Return $ini
    }
    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}
