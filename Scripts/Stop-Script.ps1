# https://www.autohotkey.com/boards/viewtopic.php?f=83&t=140432
<#
.SYNOPSIS
    Stops running scripts by name.

.DESCRIPTION
    Stops running scripts by searching for processes associated with the specified script names (processes with files in command line).

    The function tries multiple methods sequentially (including Stop-HiddenScript function) and returns after the first successful termination method.

.PARAMETER names
    Specifies the names of the scripts to stop.

    Type: String[]
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: True

.PARAMETER launcher
    Specifies the owner/launcher of the script (e.g., "autohotkey", "python").
    This is used to filter processes by name pattern. Cannot be empty.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: autohotkey
    Accept pipeline input: False
    Accept wildcard characters: True

.PARAMETER force
    Stops the specified scripts without prompting for confirmation.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER confirm
    Prompts for confirmation before stopping each script.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.INPUTS
    System.String[]

    You can pipe script names to this function.

.OUTPUTS
    None

    The function outputs a formatted table of terminated processes showing Id and
    ProcessName, along with status messages indicating success or failure.

.NOTES
    Requirements:
    - es.exe (Everything search tool) for additional search method.
    - Administrative privileges may be required for some processes.

    See Stop-HiddenScript for multiple scripts termination without specifying launcher.

.EXAMPLE
    Stop-Script "Script1", "Script2"

    Stops multiple AutoHotkey scripts at once.

.EXAMPLE
    Stop-Script "Script1", "Script2" -confirm

    Prompts for confirmation before terminating each found script.

.EXAMPLE
    kills -names "Script1.py", "Script2.py" -launcher "python" -force

    Stops a Python scripts by specifying launcher.

.LINK
    Stop-Process

.LINK
    Get-Process

.LINK
    Get-CimInstance

.LINK
    Stop-HiddenScript
#>
function Stop-Script {
    [CmdletBinding()]
    [alias('kills', 'stop')]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$names,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$launcher = "autohotkey",

        [Parameter()]
        [switch]$force,

        [Parameter()]
        [switch]$confirm
    )

    begin {
        # for Stop-Process
        $params = @{ 
            PassThru = $true
            force    = $force
            confirm  = $confirm
        }

        function Try-Kill($id) {
            if (!$id) { return $false }

            $proc = Stop-Process -id $id @params
            if ($proc) {
                $proc | Format-Table Id, ProcessName | Out-Host

                Write-Host "$launcher script '" -f DarkGray -n
                Write-Host "$name"        -f DarkCyan -n
                Write-Host "' is "        -f DarkGray -n
                Write-Host "terminated"   -f Green

                return $true
            }

            return $false
        }
        
        # for getters using Where-Object
        $filter = {
            $_.Name -like "$launcher*" -and
            $_.CommandLine -like "*$name*"
        }
    }

    process {
        ForEach ($name in $names) {
            # Try different methods
            $proc = Get-Process | Where $filter
            if (Try-Kill $proc.Id) { continue }

            $proc = Get-CimInstance Win32_Process | Where $filter
            if (Try-Kill $proc.processId) { continue }

            $proc = Get-CimInstance Win32_Process -filter "name like '$launcher%' and CommandLine like '%$name%'"
            if (Try-Kill $proc.processId) { continue }

            # Fallback to Everything search
            if (Stop-HiddenScript $name $launcher -force:$force -confirm:$confirm) { continue }

            Write-Warning "Unable to find $launcher script '$name'"
        }
    }
}


<#
.SYNOPSIS
    Stops hidden running scripts by path or name.

.DESCRIPTION
    Stops running scripts by searching for hidden windows with specified script paths in the title.

    You can specify full or relative paths to the scripts or just filenames to find all matches using Everything search tool and terminate them.

.PARAMETER names
    Specifies the paths/names of the scripts to stop.

    Type: String[]
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: False

.PARAMETER launcher
    Specifies the owner/launcher of the script (e.g., "autohotkey", "python").
    This is used to filter processes by name pattern. If empty or missing, function terminates everything that was found by $names.

    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER force
    Stops the specified/found scripts without prompting for confirmation.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.PARAMETER confirm
    Prompts for confirmation before stopping each specified/found script.

    Type: SwitchParameter
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: Named
    Default value: False
    Accept pipeline input: False
    Accept wildcard characters: False

.INPUTS
    System.String[]

    You can pipe script names to this function.

.OUTPUTS
    None

.EXAMPLE
    Stop-HiddenScript "C:\Script1.ahk", "C:\Script2.py"

    Stops multiple scripts at once.

.EXAMPLE
    Stop-Script "Script1.ahk", "Script2.py" -confirm

    Searches for scripts and prompts for confirmation before terminating each found script.

.EXAMPLE
    Stop-HiddenScript -names "Script1.py", "Script2.py" -launcher "python" -force

    Searches for Python scripts and terminates them if they are launched using "python" process.

.NOTES
    Requirements:
    - es.exe (Everything search tool) for search method.
    - Administrative privileges may be required for some processes

    See Stop-Script for termination without search tool.

.LINK
    tasklist.exe

.LINK
    taskkill.exe
#>
function Stop-HiddenScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$names,

        [Parameter()]
        [AllowEmptyString()]
        [string]$launcher = "",

        [Parameter()]
        [switch]$force,

        [Parameter()]
        [switch]$confirm
    )

    process {
        # Resolve passed names
        $scripts = @{}
        ForEach ($name in $names) {
            if (Test-Path $name) {
                $files = (Resolve-Path $name).Path
            } else {
                try {
                    $files = es.exe file:nopath:"$name" 2>$null
                } catch [System.Management.Automation.CommandNotFoundException] {
                    Write-Warning "Unable to find '$name': Everything search tool (es.exe) is not installed."
                    continue
                }
            }

            if (-not $files) {
                Write-Warning "Unable to find '$name': change the name and try again."
                continue
            }


            # Find matching scripts and get their PID
            ForEach ($file in $files) {
                # tasklist.exe params
                $params = [System.Collections.Generic.List[string]]@(
                    '-nh',                              # No table header
                    '-fo', "csv",                       # Output in CSV style
                    '-fi', "WindowTitle eq $file*"      # Search for path in WindowTitle
                )

                if ($launcher) {
                    # Process name must contain launcher name
                    $params.Add('-fi')
                    $params.Add("ImageName eq $launcher*")
                }

                # Get PIDs
                (tasklist.exe @params) | ForEach {
                    $id = ($_.Split(',').Trim('"'))[1]

                    if ($id -match '^\d+$') {
                        $scripts.Add($id, $file)
                    }
                }
            }
        }

        if (-not $scripts.count) {
            return $false
        }

        :StopScripts ForEach ($s in $scripts.GetEnumerator()) {
            :AskConfirm while ($confirm) {
                Write-Host "Terminate '" -n
                Write-Host "$($s.Value)" -f DarkCyan -n
                Write-Host "'?"

                $response = Read-Host "[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is `"Y`")"

                :AnalyzeResponse switch ($response) {
                    'A' { $confirm = $false; break AskConfirm }
                    'Y' { break AskConfirm }
                    'N' { continue StopScripts }
                    'L' { return $false }
                    'S' { exit 1 }

                    default {
                        Write-Host "Y - Terminate current process.`nA - Terminate all processes without prompting`nN - Skip current process.`nL - Skip all remaining processes.`nS - Pause current operation and return to the command prompt."
                        continue AskConfirm
                    }
                }
            }

            if ($force) {
                taskkill.exe -pid $s.Key -f 1>$null
            } else {
                taskkill.exe -pid $s.Key 1>$null
            }

            if ($LastExitCode -eq 0) {
                Write-Host "$launcher script '" -f DarkGray -n
                Write-Host "$($s.Value)"        -f DarkCyan -n
                Write-Host "' ($($s.Key)) is "  -f DarkGray -n
                Write-Host "terminated"         -f Green
            }
        }

        return $true
    }
}