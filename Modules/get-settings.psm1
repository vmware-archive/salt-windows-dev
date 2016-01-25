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
            "SaltRepo"    = "https://repo.saltstack.com/windows/dependencies"
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
            "Backports"  = "backports.ssl_match_hostname-3.4.0.2.tar.gz"
            "Certifi"    = "certifi-2015.04.28-py2.py3-none-any.whl"
            "DateUtil"   = "python_dateutil-2.4.2-py2.py3-none-any.whl"
            "Futures"    = "futures-3.0.3.tar.gz"
            "GnuGPG"     = "python-gnupg-0.3.7.tar.gz"
            "ioloop"     = "ioloop-0.1a.tar.gz"
            "Jinja"      = "Jinja2-2.7.3-py27-none-any.whl"
            "MarkupSafe" = "MarkupSafe-0.23.tar.gz"
            "MsgPack"    = "msgpack-python-0.4.6.tar.gz"
            "Pip"        = "get-pip-7.1.0.py"
            "Pip-Wheel"  = "pip-7.1.0-py2.py3-none-any.whl"
            "PyMySQL"    = "PyMySQL-0.6.6-py2.py3-none-any.whl"
            "PyYAML"     = "PyYAML-3.11.tar.gz"
            "Requests"   = "requests-2.5.3-py2.py3-none-any.whl"
            "SetupTools" = "setuptools-17.0-py2.py3-none-any.whl"
            "Six"        = "six-1.9.0-py2.py3-none-any.whl"
            "Tornado"    = "tornado-4.2.1.tar.gz"
            "Wheel"      = "wheel-0.24.0-py2.py3-none-any.whl"
            "WMI"        = "WMI-1.4.9-py2-none-any.whl"
        }
        $ini.Add("CommonPrograms", $CommonPrograms)

        # Filenames for 64 bit Windows
        $64bitPrograms = @{
            "PSUtil"     = "psutil-3.1.1-cp27-none-win_amd64.whl"
            "PyCrypto"   = "pycrypto-2.6.1-cp27-none-win_amd64.whl"
            "Python"     = "python-2.7.11.amd64.msi"
            "PyWin"      = "pypiwin32-219-cp27-none-win_amd64.whl"
            "PyZMQ"      = "pyzmq-14.7.0-cp27-none-win_amd64.whl"
        }
        $ini.Add("64bitPrograms", $64bitPrograms)

        # Filenames for 32 bit Windows
        $32bitPrograms = @{
            "PSUtil"     = "psutil-3.1.1-cp27-none-win32.whl"
            "PyCrypto"   = "pycrypto-2.6.1-cp27-none-win32.whl"
            "Python"     = "python-2.7.11.msi"
            "PyWin"      = "pypiwin32-219-cp27-none-win32.whl"
            "PyZMQ"      = "pyzmq-14.7.0-cp27-none-win32.whl"
        }
        $ini.Add("32bitPrograms", $32bitPrograms)

        # CPU Architecture Independent DLL's
        $CommonDLLs = @{
            "libsodium" = "libsodium-13.dll"
        }
        $ini.Add("CommonDLLs", $CommonDLLs)

        # DLL's for 64 bit Windows
        $64bitDLLs = @{
            "Libeay"     = "libeay32.dll"
            "SSLeay"     = "ssleay32.dll"
            "OpenSSLLic" = "OpenSSL_License.txt"
        }
        $ini.Add("64bitDLLs", $64bitDLLs)

        # DLL's for 32 bit Windows
        $32bitDLLs = @{
            "Libeay"     = "libeay32.dll"
            "SSLeay"     = "ssleay32.dll"
            "OpenSSLLic" = "OpenSSL_License.txt"
        }
        $ini.Add("32bitDLLs", $32bitDLLs)

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Loading Settings"
        Return $ini
    }
    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}
