$ErrorActionPreference = 'Stop';

$toolsDir       = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

#Grafana
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = 'GrafanaOSS*'
  fileType       = 'msi'
  silentArgs     = "/qn /norestart /l*v `"$env:TEMP\$env:ChocolateyPackageName.$env:ChocolateyPackageVersion.log`""
  file           = "$toolsdir\grafana-8.1.0.windows-amd64.msi"
  validExitCodes = @(0,1641,3010)
}

Write-Verbose "Downloading and installing program..."
Install-ChocolateyInstallPackage @packageArgs

Get-ChildItem $toolsPath\*.msi | ForEach-Object { Remove-Item $_ -ea 0; if (Test-Path $_) { Set-Content "$_.ignore" } }

$ServiceName = 'Grafana'

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
  if ($Service.Status -eq "Running") {
      Start-ChocolateyProcessAsAdmin "stop $ServiceName" nssm
  }   
}

Copy-Item -Path "C:\ProgramData\chocolatey\lib\local-dashboards\tools\datasources.yml" -Destination "C:\Program Files\GrafanaLabs\grafana\conf\provisioning\datasources\custom.yml" -Force

Start-ChocolateyProcessAsAdmin "start $ServiceName" nssm

# Prometheus
$ServiceName = 'Prometheus'

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
  if ($Service.Status -eq "Running") {
      Start-ChocolateyProcessAsAdmin "stop $ServiceName" nssm
  } 
  Start-ChocolateyProcessAsAdmin "remove $ServiceName confirm" nssm
}

New-Item -ItemType Directory -Path 'C:\Program Files\Prometheus\' -Force 
Get-ChocolateyUnzip -FileFullPath 'C:\ProgramData\chocolatey\lib\local-dashboards\tools\prometheus-2.2.1.windows-amd64.zip' -destination 'C:\Program Files\Prometheus\'
Copy-Item -Path "C:\ProgramData\chocolatey\lib\local-dashboards\tools\prometheus.yml" -Destination "C:\Program Files\Prometheus\prometheus.yml" -Force

Write-Host "Installing service"
Start-ChocolateyProcessAsAdmin "install $ServiceName ""C:\Program Files\Prometheus\prometheus.exe""" nssm
Start-ChocolateyProcessAsAdmin "set $ServiceName Start SERVICE_AUTO_START" nssm
#nssm start "$ServiceName"  

# Prometheus Url Tester
$ServiceName = 'PrometheusUrlTester'

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
  if ($Service.Status -eq "Running") {
      Start-ChocolateyProcessAsAdmin "stop $ServiceName" nssm
  }
  Start-ChocolateyProcessAsAdmin "remove $ServiceName confirm" nssm
}

New-Item -ItemType Directory -Path 'C:\Program Files\Prometheus Url Tester\' -Force
Get-ChocolateyUnzip -FileFullPath 'C:\ProgramData\chocolatey\lib\local-dashboards\tools\blackbox_exporter-0.12.0.windows-amd64.zip' -destination 'C:\Program Files\Prometheus Url Tester\'

Write-Host "Installing service"



Start-ChocolateyProcessAsAdmin "install $ServiceName ""C:\Program Files\Prometheus Url Tester\blackbox_exporter.exe""" nssm
Start-ChocolateyProcessAsAdmin "set $ServiceName Start SERVICE_AUTO_START" nssm
#Start-ChocolateyProcessAsAdmin "start $ServiceName" nssm
