<#
.SYNOPSIS
    Counts the total number of lines in files within a specified path.

.DESCRIPTION
    Recursively searches for scripts in the specified directory and counts the total lines across all files.
    Displays individual file line counts and a total summary.

.PARAMETER Path
    The root path to search for. Defaults to current directory.
    
    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: True
    Position: 0
    Default value: None
    Accept pipeline input: True (ByValue)
    Accept wildcard characters: True
    
.PARAMETER Filter
    File filter pattern. Defaults to *.ahk.
    
    Type: String
    Parameter Sets: (All)
    Aliases:

    Required: False
    Position: 1
    Default value: None
    Accept pipeline input: False
    Accept wildcard characters: False

.EXAMPLE
    Get-LineCount -Path "C:\Scripts"

.EXAMPLE
    Get-LineCount -Path "Build.ahk" -Recurse

.OUTPUTS
    PSCustomObject with properties: FullName, LineCount
#>
function Get-LineCount {    
    [CmdletBinding()]
    [alias('lines')]
    
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]
        $Path = ".",
        
        [Parameter(Mandatory = $false)]
        [string]
        $Filter = "*.ahk"
    )
    
    begin {
        $totalLines = 0
        $fileCount  = 0
        $results    = [System.Collections.Generic.List[PSCustomObject]]@()
    }
    
    process {
        $files = Get-ChildItem `
            -Path $Path -Filter $Filter `
            -ErrorAction SilentlyContinue `
            -Recurse
        
        if (-not $files) {
            Write-Warning "No $Filter files found in `"$Path`""
            return
        }
        
        foreach ($file in $files) {
            $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
            
            if ($null -eq $content) {
                $lineCount = 0
            } elseif ($content -is [string]) {
                $lineCount = 1
            } else {
                $lineCount = $content.Count
            }
            
            $totalLines += $lineCount
            $fileCount++
            
            $results.Add([PSCustomObject]@{
                FullName  = $file.FullName
                LineCount = $lineCount
            })
        }
    }
    
    end {
        $results | Format-Table -AutoSize
        
        Write-Output "Total Files: $fileCount"
        Write-Output "Total Lines: $totalLines"
        
        # [PSCustomObject]@{
            # TotalFiles = $fileCount
            # TotalLines = $totalLines
            # Files      = $results
        # }
    }
}