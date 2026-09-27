$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = "flutter.bat"
$processInfo.Arguments = "doctor --android-licenses"
$processInfo.RedirectStandardInput = $true
$processInfo.RedirectStandardOutput = $true
$processInfo.UseShellExecute = $false

$process = [System.Diagnostics.Process]::Start($processInfo)
Start-Sleep -Seconds 5

# Keep writing "y" to the process input
for ($i = 0; $i -lt 20; $i++) {
    try {
        $process.StandardInput.WriteLine("y")
    } catch {}
    Start-Sleep -Milliseconds 300
}
$process.WaitForExit()
