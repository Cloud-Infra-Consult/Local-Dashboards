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

Copy-Item  -Path "$env:ChocolateyPackageFolder\tools\datasources.yml" -Destination "C:\Program Files\GrafanaLabs\grafana\conf\provisioning\datasources\custom.yml" -Force -Verbose
Copy-Item  -Path "$env:ChocolateyPackageFolder\tools\dashboards.yml" -Destination "C:\Program Files\GrafanaLabs\grafana\conf\provisioning\dashboards\dashboard.yml" -Force -Verbose
Copy-Item  -Path "$env:ChocolateyPackageFolder\tools\website.dashboards.json" -Destination "C:\Program Files\GrafanaLabs\grafana\conf\provisioning\dashboards\website.json" -Force -Verbose

Start-ChocolateyProcessAsAdmin "start $ServiceName" nssm -ErrorAction SilentlyContinue

# Prometheus
$ServiceName = 'Prometheus'

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
  if ($Service.Status -eq "Running") {
      Start-ChocolateyProcessAsAdmin "stop $ServiceName" nssm
  } 
  Start-ChocolateyProcessAsAdmin "remove $ServiceName confirm" nssm
}

New-Item -ItemType Directory -Path 'C:\Program Files\Prometheus\' -Force 
Get-ChocolateyUnzip -FileFullPath "$env:ChocolateyPackageFolder\tools\prometheus-2.2.1.windows-amd64.zip" -destination 'C:\Program Files\Prometheus\'
Copy-Item -Path "$env:ChocolateyPackageFolder\tools\prometheus.yml" -Destination "C:\Program Files\Prometheus\prometheus.yml"

Write-Host "Installing service"
Start-ChocolateyProcessAsAdmin "install $ServiceName ""C:\Program Files\Prometheus\prometheus.exe""" nssm
Start-ChocolateyProcessAsAdmin "set $ServiceName Start SERVICE_AUTO_START" nssm

# Prometheus Url Tester
$ServiceName = 'PrometheusUrlTester'

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
  if ($Service.Status -eq "Running") {
      Start-ChocolateyProcessAsAdmin "stop $ServiceName" nssm
  }
  Start-ChocolateyProcessAsAdmin "remove $ServiceName confirm" nssm
}

New-Item -ItemType Directory -Path 'C:\Program Files\Prometheus Url Tester\' -Force
Get-ChocolateyUnzip -FileFullPath "$env:ChocolateyPackageFolder\tools\blackbox_exporter-0.12.0.windows-amd64.zip" -destination 'C:\Program Files\Prometheus Url Tester\'

Write-Host "Installing service"

Start-ChocolateyProcessAsAdmin "install $ServiceName ""C:\Program Files\Prometheus Url Tester\blackbox_exporter.exe""" nssm
Start-ChocolateyProcessAsAdmin "set $ServiceName Start SERVICE_AUTO_START" nssm

Start-ChocolateyProcessAsAdmin "start Prometheus" nssm -ErrorAction SilentlyContinue -ValidExitCodes @(0,1)
Start-ChocolateyProcessAsAdmin "start PrometheusUrlTester" nssm -ErrorAction SilentlyContinue -ValidExitCodes @(0,1)

$path = "C:\Program Files\Prometheus\prometheus.yml"
$acl = Get-Acl $path
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users","FullControl","Allow")
$acl.SetAccessRule($AccessRule)
$acl | Set-Acl $path

