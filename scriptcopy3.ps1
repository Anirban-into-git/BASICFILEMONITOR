function Add-FileToBaseline {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]$baselineFilePath,
        [Parameter(Mandatory)]$targetFilePath
    )
    try {
        if ((Test-Path -Path $baselineFilePath) -eq $false) {
            Write-Error -Message "$baselineFilePath does not exist" -ErrorAction Stop
        }
        
        if ((Test-Path -Path $targetFilePath) -eq $false) {
            Write-Error -Message "$targetFilePath does not exist" -ErrorAction Stop
        }

        $currentBaseline = Import-Csv -Path $baselineFilePath -Delimiter ","
        if ($currentBaseline.path -contains $targetFilePath) {
            Write-Output "File path already detected in baseline file"
            do {
                $overwrite = Read-Host -Prompt "Path already exists in the baseline file, Do you like to overwrite it? [Y/N]:"
                if ($overwrite -in @('y','yes')) {
                    Write-Output "File path will be overwritten"
                    $updatedBaseline = $currentBaseline | Where-Object { $_.path -ne $targetFilePath }
                    
                    $hash = Get-FileHash -Path $targetFilePath
                    $updatedBaseline += [PSCustomObject]@{path=$targetFilePath; hash=$hash.Hash}

                    $updatedBaseline | Export-Csv -Path $baselineFilePath -Delimiter "," -NoTypeInformation

                    Write-Output "Entry successfully updated in the baseline."
                } elseif ($overwrite -in @('n','no')) {
                    Write-Output "File path will not be overwritten"
                } else {
                    Write-Output "Invalid input"
                }
            } while ($overwrite -notin @('y','yes','n','no'))
            
        } else {
            $hash = Get-FileHash -Path $targetFilePath
            "$($targetFilePath),$($hash.Hash)" | Out-File -FilePath $baselineFilePath -Append
            
            # Read the CSV file as plain text
            $csvContent = Get-Content -Path $baselineFilePath -Raw
            
            # Remove null characters
            $cleanCsvContent = $csvContent -replace "`0", ""
            
            # Save the cleaned content back to the CSV file (optional)
            $cleanCsvContent | Set-Content -Path $baselineFilePath
            Write-Output "Entry successfully added to baseline."
        }
    }
    catch {
        return $_.Exception.Message
    }
}

function Verify-Baseline {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]$baselineFilePath
    )
    try {
        if ((Test-Path -Path $baselineFilePath) -eq $false) {
            Write-Error -Message "$baselineFilePath does not exist" -ErrorAction Stop
        }

        # Read the CSV file as plain text
        $csvContent = Get-Content -Path $baselineFilePath -Raw

        # Remove null characters
        $cleanCsvContent = $csvContent -replace "`0", ""

        # Import the cleaned CSV content
        $baselineFiles = $cleanCsvContent | ConvertFrom-Csv -Delimiter ","

        foreach ($file in $baselineFiles) {
            # Remove any remaining null characters from the path and hash fields
            $cleanPath = $file.path -replace "`0", ""
            $cleanHash = $file.hash -replace "`0", ""

            if (Test-Path -Path $cleanPath) {
                $currentHash = Get-FileHash -Path $cleanPath
                if ($currentHash.Hash -eq $cleanHash) {
                    Write-Output "File $($cleanPath) hash is SAME"
                } else {
                    Write-Output "File $($cleanPath) hash is different, something has changed"
                }
            } else {
                Write-Output "$($cleanPath) is not found"
            }
        }
    }
    catch {
        return $_.Exception.Message
    }
}

function Create-Baseline {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]$baselineFilePath
    )
    try {
        if (Test-Path -Path $baselineFilePath) {
            Write-Error -Message "$baselineFilePath already exists" -ErrorAction Stop
        }

        "path,hash" | Out-File $baselineFilePath -Force
    }
    catch {
        return $_.Exception.Message
    }
}

$baselineFilePath = "D:\BASICFILEMONITOR\baselines1.csv"
Create-Baseline -baselineFilePath $baselineFilePath
Add-FileToBaseline -baselineFilePath $baselineFilePath -targetFilePath "D:\BASICFILEMONITOR\Files\test2.txt"

Verify-Baseline -baselineFilePath $baselineFilePath
