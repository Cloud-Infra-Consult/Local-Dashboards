$ServiceName="Prometheus"

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Removing service."
    if ($Service.Status -eq "Running") {
        Start-ChocolateyProcessAsAdmin "stop $ServiceName" "sc.exe"
    }
    Start-ChocolateyProcessAsAdmin "delete $ServiceName" "sc.exe"
}

Remove-Item -Path 'C:\Program Files\Prometheus' -Force

$ServiceName="PrometheusUrlTester"

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Removing service."
    if ($Service.Status -eq "Running") {
        Start-ChocolateyProcessAsAdmin "stop $ServiceName" "sc.exe"
    }
    Start-ChocolateyProcessAsAdmin "delete $ServiceName" "sc.exe"
}

Remove-Item -Path 'C:\Program Files\Prometheus Url Tester' -Force