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
try {
  $catalog = Get-Content $CatalogPath -Raw | ConvertFrom-Json
  $map = @{}
  foreach ($s in $catalog.skills) { $map[$s.id]=$s }
  $ids = @()
  if ($Profile) {
    $profiles = Get-Content $ProfilesPath -Raw | ConvertFrom-Json
    $ids = @($profiles.$Profile)
    if (-not $ids -or $ids.Count -eq 0) { throw "Profile not found: $Profile" }
  }
  if ($Skills) { $ids = @($ids) + @($Skills) }
  $ids = $ids | Sort-Object -Unique

  function Resolve-SourcePath($s) {
    $parts = $s.path.Split('\')
    $dir = Join-Path $PSScriptRoot 'skills'
    for ($i=0; $i -lt $parts.Length-1; $i++) { $dir = Join-Path $dir $parts[$i] }
    return $dir
  }
  function Test-SkillMd($dir) {
    $f = Join-Path $dir 'SKILL.md'
    if (-not (Test-Path $f)) { throw "Missing SKILL.md: $dir" }
    $content = Get-Content $f -Raw
    if ($content -notmatch '(?m)^name:\s*\S+') { throw "Invalid SKILL.md (name): $f" }
    if ($content -notmatch '(?m)^description:\s*\S+') { throw "Invalid SKILL.md (description): $f" }
  }

  $manifestData = @{}
  if (Test-Path $Manifest) {
    $obj = Get-Content $Manifest -Raw | ConvertFrom-Json
    foreach ($p in $obj.PSObject.Properties) { $manifestData[$p.Name] = $p.Value }
  }

  if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }

  foreach ($id in $ids) {
    $s = $map[$id]
    if (-not $s) { throw "Unknown skill: $id" }
    $src = Resolve-SourcePath $s
    Test-SkillMd $src
    $destName = $s.skill
    $dest = Join-Path $Target $destName
    if (Test-Path $dest) {
      $tracked = $manifestData.ContainsKey($destName)
      $same = $tracked -and ($manifestData[$destName].id -eq $id)
      if (-not $same) {
        $destName = "$($s.origin)-$($s.skill)"
        $dest = Join-Path $Target $destName
      }
    }
    $exists = Test-Path $dest
    $conflict = $exists -and -not $manifestData.ContainsKey($destName)
    Write-Host ("[{0}] {1} -> {2} {3}{4}" -f $Action,$id,$dest,$(if($exists){'EXISTS'}else{'NEW'}),$(if($conflict){' CONFLICT'}else{''}))
    if ($Action -eq 'dry-run') { continue }
    if ($conflict -and -not $Force) { throw "Conflict: $destName" }
    if ($exists -and -not $Force -and $Action -ne 'update') { Write-Host "  SKIP (exists)"; continue }

    $backup = $null
    if (Test-Path $dest) {
      $backup = "$dest.bak-$(Get-Date -Format yyyyMMddHHmmss)"
      Copy-Item -Recurse -Force $dest $backup
    }
    try {
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse -Force $src $dest
      Test-SkillMd $dest
      if ($backup) { Remove-Item -Recurse -Force $backup }
    } catch {
      if ($backup -and (Test-Path $backup)) {
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        Move-Item -Force $backup $dest
      }
      throw
    }
    $manifestData[$destName] = @{ id=$id; version=$s.version; origin=$s.origin; installed=(Get-Date).ToString('o') }
    Write-Host "  INSTALLED"
  }

  if ($Action -eq 'uninstall') {
    foreach ($id in $ids) {
      $s = $map[$id]
      $destName = if ($s) { $s.skill } else { $id }
      if (-not $manifestData.ContainsKey($destName)) {
        $alt = if ($s) { "$($s.origin)-$($s.skill)" } else { $null }
        if ($alt -and $manifestData.ContainsKey($alt)) { $destName = $alt }
      }
      $dest = Join-Path $Target $destName
      if (Test-Path $dest) {
        if (-not $Force -and -not $manifestData.ContainsKey($destName)) { throw "Not tracked: $destName" }
        Remove-Item -Recurse -Force $dest
        $manifestData.Remove($destName) | Out-Null
        Write-Host "REMOVED $destName"
      }
    }
  }

  if ($Action -ne 'dry-run') {
    $manifestData | ConvertTo-Json -Depth 5 | Set-Content $Manifest
  }
  Write-Host "DONE"
} catch {
  Write-Error $_
  exit 1
}
PS