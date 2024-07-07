$baselineFilePath = "D:\BASICFILEMONITOR\baselines.csv"
$fileToMonitorPath = "D:\BASICFILEMONITOR\Files\test.txt"
$fileToMonitorPath = "D:\BASICFILEMONITOR\Files\test1.txt"

# Add a file to the baseline CSV
$hash = Get-FileHash -Path $fileToMonitorPath
"$($fileToMonitorPath),$($hash.Hash)" | Out-File -FilePath $baselineFilePath -Append

# Read the CSV file as plain text
$csvContent = Get-Content -Path $baselineFilePath -Raw

# Remove null characters
$cleanCsvContent = $csvContent -replace "`0", ""

# Save the cleaned content back to the CSV file (optional)
$cleanCsvContent | Set-Content -Path $baselineFilePath

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
