param(
  [Parameter(Mandatory=$true)][ValidateSet('install','update','uninstall','dry-run')][string]$Action,
  [string]$Profile,
  [string[]]$Skills,
  [string]$CatalogPath,
  [string]$ProfilesPath,
  [string]$Target,
  [string]$Manifest,
  [switch]$Force
)
$ErrorActionPreference='Stop'
if (-not $CatalogPath) { $CatalogPath = Join-Path $PSScriptRoot 'CATALOG.json' }
if (-not $ProfilesPath) { $ProfilesPath = Join-Path $PSScriptRoot 'profiles\profiles.json' }
if (-not $Target) { $Target = Join-Path $HOME '.kilo\skills' }
if (-not $Manifest) { $Manifest = Join-Path $Target '.ai-fullstack-manifest.json' }

function Fail($msg) { Write-Error $msg; exit 1 }

try {
  $catalog = Get-Content $CatalogPath -Raw | ConvertFrom-Json
  $mapById = @{}
  $mapByInvocation = @{}
  foreach ($s in $catalog.skills) {
    $mapById[$s.id] = $s
    $inv = if ($s.PSObject.Properties.Name -contains 'invocation_name') { $s.invocation_name } else { $s.skill }
    if (-not $mapByInvocation.ContainsKey($inv)) { $mapByInvocation[$inv] = @() }
    $mapByInvocation[$inv] += @($s)
  }

  function Resolve-SkillId($ref) {
    # Tenta por id completo (origin/skill)
    if ($mapById.ContainsKey($ref)) { return $ref }
    # Tenta por invocation_name (se ambiguo, retorna null para o chamador decidir)
    $matches = $mapByInvocation[$ref]
    if ($matches -and $matches.Count -eq 1) { return $matches[0].id }
    if ($matches -and $matches.Count -gt 1) {
      $ids = ($matches | ForEach-Object { $_.id }) -join ', '
      Fail "Referencia ambigua '$ref': $ids. Use o id completo (ex.: origem/skill)."
    }
    Fail "Skill desconhecida: $ref"
  }

  $ids = @()
  if ($Profile) {
    $profiles = Get-Content $ProfilesPath -Raw | ConvertFrom-Json
    $ids = @($profiles.$Profile)
    if (-not $ids -or $ids.Count -eq 0) { Fail "Profile not found: $Profile" }
  }
  if ($Skills) {
    foreach ($ref in $Skills) {
      $ids += @(Resolve-SkillId $ref)
    }
  }
  $ids = $ids | Sort-Object -Unique

  function Resolve-SourcePath($s) {
    $parts = $s.path.Split('\')
    $dir = Join-Path $PSScriptRoot 'skills'
    for ($i=0; $i -lt $parts.Length-1; $i++) { $dir = Join-Path $dir $parts[$i] }
    return $dir
  }
  function Get-InvocationName($s) {
    if ($s.PSObject.Properties.Name -contains 'invocation_name') { return $s.invocation_name }
    return $s.skill
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

  if ($Action -eq 'uninstall') {
    foreach ($id in $ids) {
      $s = $mapById[$id]
      $destName = if ($s) { $s.skill } else { $id }
      if (-not $manifestData.ContainsKey($destName)) {
        $alt = if ($s) { "$($s.origin)-$($s.skill)" } else { $null }
        if ($alt -and $manifestData.ContainsKey($alt)) { $destName = $alt }
      }
      $dest = Join-Path $Target $destName
      if (Test-Path $dest) {
        if (-not $Force -and -not $manifestData.ContainsKey($destName)) { Fail "Not tracked: $destName" }
        Remove-Item -Recurse -Force $dest
        $manifestData.Remove($destName) | Out-Null
        Write-Host "REMOVED $destName"
      }
    }
    $manifestData | ConvertTo-Json -Depth 5 | Set-Content $Manifest
    Write-Host "DONE"
    exit 0
  }

  foreach ($id in $ids) {
    $s = $mapById[$id]
    if (-not $s) { Fail "Unknown skill: $id" }
    $src = Resolve-SourcePath $s
    Test-SkillMd $src
    $invocationName = Get-InvocationName $s
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
    # Detectar conflito de invocation_name: outro destino ja usa esse invocation_name
    $invConflict = $null
    foreach ($mKey in $manifestData.Keys) {
      $mVal = $manifestData[$mKey]
      if ($mVal.PSObject.Properties.Name -contains 'invocation_name' -and $mVal.invocation_name -eq $invocationName -and $mVal.id -ne $id) {
        $invConflict = $mKey
      }
    }
    Write-Host ("[{0}] {1} -> {2} (invocation={3}) {4}{5}{6}" -f $Action,$id,$dest,$invocationName,$(if($exists){'EXISTS'}else{'NEW'}),$(if($conflict){' CONFLICT'}else{''}),$(if($invConflict){" INVOCATION_CONFLICT_WITH=$invConflict"}else{''}))
    if ($Action -eq 'dry-run') { continue }
    if ($conflict -and -not $Force) { Fail "Conflict: $destName" }
    if ($invConflict -and -not $Force) { Fail "Invocation name '$invocationName' already used by '$invConflict'. Use -Force to override." }
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
    $entry = @{ id=$id; skill=$s.skill; invocation_name=$invocationName; version=$s.version; origin=$s.origin; installed=(Get-Date).ToString('o') }
    $manifestData[$destName] = $entry
    Write-Host "  INSTALLED"
  }

  if ($Action -ne 'dry-run') {
    $manifestData | ConvertTo-Json -Depth 5 | Set-Content $Manifest
  }
  Write-Host "DONE"
  exit 0
} catch {
  Write-Error $_
  exit 1
}
