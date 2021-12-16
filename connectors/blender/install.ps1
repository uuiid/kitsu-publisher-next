 param (
    [switch]$help = $false,
    [switch]$installer = $false,
    [string]$portable = ""
 )

function Get-Help {
    # Display Help
    Write-Output "Script to install Blender plugin for the Kitsu Publisher."
    Write-Output ""
    Write-Output "Usage: install.ps1 [options]"
    Write-Output "options:"
    Write-Output "-help"
    Write-Output "  Print this help."
    Write-Output "-installer"
    Write-Output "  Install the plugin for an installer installation."
    Write-Output "-portable PATH"
    Write-Output "  Install the plugin for a portable directory installation. You need to specify the path to this directory."
}

function Install-Pip {
    Write-Output "Installation of pip."
    & $python_executable -m ensurepip --upgrade
    Write-Output "Pip installed."
}

function Install {
    Write-Output "Installation of the plugin."
    $blender_addons_path = [IO.Path]::Combine($env:APPDATA, "Blender Foundation", "Blender", $blender_version, "scripts", "addons")
    & $python_executable -m pip install $PSScriptRoot -t ([IO.Path]::Combine($blender_addons_path, "modules")) -U
    Copy-Item -Path ([IO.Path]::Combine($PSScriptRoot, "kitsu-publisher.py")) ([IO.Path]::Combine($blender_addons_path)) -force
    Write-Output "Plugin for blender installed in $blender_addons_path"
    Write-Output "Enabling the plugin in Blender."
    & $blender_executable -b -P ([IO.Path]::Combine($PSScriptRoot, "auto-enable.py"))
    Write-Output "Plugin enabled."
}

if($help)
{
    Get-Help
} elseif ($installer)
{
    $UninstallKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
                    )
    foreach ($key in (Get-ChildItem $UninstallKeys)) {
        if ($key.getValue("DisplayName") -eq "blender" ) {
            $blender_executable = [IO.Path]::Combine($key.getValue("InstallLocation"), "blender.exe")
            if (Test-Path $blender_executable) 
            {
                $blender_version = (((cmd.exe /c $blender_executable -v) | Out-String) -split '\n')[0] 
                $blender_version = ($blender_version -split ' ')[1] -split '\.'
                $blender_version = $blender_version[0] + "." + $blender_version[1]
                $python_executable = (Get-ChildItem -Path ([IO.Path]::Combine($key.getValue("InstallLocation"), $blender_version, "python", "bin", "python*.exe"))).FullName
                Install-Pip
                Install
            }
        }
    }
} elseif ($portable)
{
    $blender_executable = [IO.Path]::Combine($portable, "blender.exe")
    if (-not (Test-Path $blender_executable)) 
    {
        throw [System.IO.FileNotFoundException] "Blender could not be found as a portable directory at $portable."
    }
    $blender_version = (((cmd.exe /c $blender_executable -v) | Out-String) -split '\n')[0] 
    $blender_version = ($blender_version -split ' ')[1] -split '\.'
    $blender_version = $blender_version[0] + "." + $blender_version[1]
    $python_executable = (Get-ChildItem -Path ([IO.Path]::Combine($portable, $blender_version, "python", "bin", "python*.exe"))).FullName
    Install-Pip
    Install
} else 
{
    throw "You need to specify a target (-help for help)."
}