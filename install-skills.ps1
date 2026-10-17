param(
  [Parameter(Mandatory=$true)][ValidateSet('install','update','uninstall','dry-run')][string]$Action,
  [string]$Profile,
  [string[]]$Skills,
  [string]$CatalogPath = (Join-Path $PSScriptRoot 'CATALOG.json'),
  [string]$ProfilesPath = (Join-Path $PSScriptRoot 'profiles\profiles.json'),
  [string]$Target = 'C:\Users\PC\.kilo\skills',
  [string]$Manifest = 'C:\Users\PC\.kilo\skills\.ai-fullstack-manifest.json',
  [switch]$Force
)
$ErrorActionPreference='Stop'
$catalog = Get-Content $CatalogPath -Raw | ConvertFrom-Json
$map = @{}
foreach ($s in $catalog.skills) { $map[$s.id]=$s }

$ids = @()
if ($Profile) {
  $profiles = Get-Content $ProfilesPath -Raw | ConvertFrom-Json
  $ids = $profiles.$Profile
  if (-not $ids) { throw "Profile not found: $Profile" }
}
if ($Skills) { $ids = $ids + $Skills }
$ids = $ids | Sort-Object -Unique

function Resolve-SourcePath($s) {
  # flatten double nesting: category/origin/skill/skill/SKILL.md -> category/origin/skill
  $parts = $s.path.Split('\')
  # path like agents\origin\skill\skill\SKILL.md
  $dir = Join-Path $PSScriptRoot 'skills'
  for ($i=0; $i -lt $parts.Length-1; $i++) { $dir = Join-Path $dir $parts[$i] }
  return $dir
}

$manifestData = @{}
if (Test-Path $Manifest) {
  $obj = Get-Content $Manifest -Raw | ConvertFrom-Json
  foreach ($p in $obj.PSObject.Properties) { $manifestData[$p.Name] = $p.Value }
}

if ($Action -eq 'dry-run' -or $Action -eq 'install' -or $Action -eq 'update') {
  foreach ($id in $ids) {
    $s = $map[$id]
    if (-not $s) { Write-Host "UNKNOWN: $id"; continue }
    $src = Resolve-SourcePath $s
    $destName = $s.skill
    $dest = Join-Path $Target $destName
    $exists = Test-Path $dest
    $conflict = $exists -and -not $manifestData.ContainsKey($destName)
    Write-Host ("[{0}] {1} -> {2} {3}{4}" -f $Action,$id,$dest,$(if($exists){'EXISTS'}else{'NEW'}),$(if($conflict){' CONFLICT'}else{''}))
    if ($Action -eq 'dry-run') { continue }
    if ($conflict -and -not $Force) { Write-Host "  SKIP (conflict, use -Force)"; continue }
    if ($exists -and -not $Force -and $Action -ne 'update') { Write-Host "  SKIP (exists)"; continue }
    # copy recursively
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Force $src $dest
    $manifestData[$destName] = @{ id=$id; version=$s.version; origin=$s.origin; installed=(Get-Date).ToString('o') }
    Write-Host "  INSTALLED"
  }
  if ($Action -ne 'dry-run') {
    $manifestData | ConvertTo-Json -Depth 5 | Set-Content $Manifest
  }
} elseif ($Action -eq 'uninstall') {
  foreach ($id in $ids) {
    $s = $map[$id]
    $destName = if ($s) { $s.skill } else { $id }
    $dest = Join-Path $Target $destName
    if (Test-Path $dest) {
      if (-not $Force -and -not $manifestData.ContainsKey($destName)) { Write-Host "SKIP (not tracked): $destName"; continue }
      Remove-Item -Recurse -Force $dest
      $manifestData.Remove($destName) | Out-Null
      Write-Host "REMOVED $destName"
    } else { Write-Host "NOT FOUND $destName" }
  }
  $manifestData | ConvertTo-Json -Depth 5 | Set-Content $Manifest
}
Write-Host "DONE"

