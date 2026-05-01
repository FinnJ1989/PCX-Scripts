# ================= CONFIG =================
$RepoOwner = "FinnJ1989" 
$RepoName = "PCX-Scripts" 
$Branch = "main"

$BaseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch" 
$LocalRoot = "$env:LOCALAPPDATA\Faze"
$Manifest = "$LocalRoot\manifest.json"
$LocalVer = "$LocalRoot\local_versions.json"
$LogFile = "$LocalRoot\update.log"

# ================= SETUP =================
New-Item -ItemType Directory -Force -Path $LocalRoot | Out-Null

function Log($msg) {
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
"$timestamp - $msg" | Out-File $LogFile -Append
}

Log "Update started"

# ================= DOWNLOAD MANIFEST =================
Invoke-WebRequest "$BaseUrl/manifest.json" -OutFile $Manifest -UseBasicParsing 
$Remote = Get-Content $Manifest | ConvertFrom-Json

# ================= LOAD LOCAL STATE =================
$Local = @{}
if (Test-Path $LocalVer) {
$Local = Get-Content $LocalVer | ConvertFrom-Json
}

# ================= PROCESS FILES =================
foreach ($file in $Remote.files) {
$name = $file.name
$ver = $file.version
$localPath = Join-Path $LocalRoot $name 
$remoteUrl = "$BaseUrl/Released/$name"

if ($Local.$name -eq $ver) {
Log "SKIP: $name already at $ver" 
continue
}

try {
if (Test-Path $localPath) {
Copy-Item $localPath "$localPath.bak" -Force
}


Invoke-WebRequest $remoteUrl -OutFile $localPath -UseBasicParsing
$Local | Add-Member -MemberType NoteProperty -Name $name -Value $ver -Force 
Log "UPDATED: $name to version $ver"
}
catch {
Log "ERROR updating $name"
}
}

# ================= SAVE STATE =================
$Local | ConvertTo-Json | Set-Content $LocalVer 
Log "Update completed"