<#
.SYNOPSIS
Checks the rules library: frontmatter, globs, skill names, cross-references, secrets, and that the router,
README, and install examples list exactly the packs and skills on disk. Ends with a test install of every pack.
Exits 1 when any error is found.

.EXAMPLE
.\validate.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$packsRoot = Join-Path $root 'packs'
$routerRel = 'packs/core/rules/00-router.mdc'
$routerPath = Join-Path $root $routerRel
$readmePath = Join-Path $root 'README.md'
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Get-Relative([string]$Path) { $Path.Substring($root.Length + 1).Replace('\', '/') }

function Read-Frontmatter([string]$Path) {
    $lines = @(Get-Content $Path)
    if ($lines.Count -lt 3 -or $lines[0] -ne '---') { return $null }
    $end = -1
    for ($i = 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -eq '---') { $end = $i; break } }
    if ($end -lt 0) { return $null }
    $fields = @{}
    for ($i = 1; $i -lt $end; $i++) {
        if ($lines[$i] -match '^([A-Za-z-]+):\s*(.*)$') { $fields[$Matches[1]] = $Matches[2].Trim() }
    }
    [pscustomobject]@{ Fields = $fields; BodyLines = $lines.Count - $end - 1 }
}

function Compare-Names([string]$Where, [string[]]$Listed, [string[]]$Actual, [string]$Kind) {
    foreach ($name in $Actual) { if ($name -notin $Listed) { $errors.Add("$Where is missing $Kind '$name'") } }
    foreach ($name in $Listed) { if ($name -notin $Actual) { $errors.Add("$Where lists $Kind '$name', which doesn't exist") } }
}

$packs = @(Get-ChildItem $packsRoot -Directory | Select-Object -ExpandProperty Name)
$skillPacks = @{}
$ruleCount = 0
$agentRequested = 0
$routerIsAlwaysOn = $false

foreach ($pack in $packs) {
    if (-not (Test-Path (Join-Path $packsRoot "$pack\rules")) -and -not (Test-Path (Join-Path $packsRoot "$pack\skills"))) {
        $errors.Add("packs/${pack}: has neither rules/ nor skills/")
    }
    foreach ($dir in Get-ChildItem (Join-Path $packsRoot "$pack\skills") -Directory -ErrorAction SilentlyContinue) {
        if (-not (Test-Path (Join-Path $dir.FullName 'SKILL.md'))) { $errors.Add("$(Get-Relative $dir.FullName): skill folder has no SKILL.md") }
    }
}

foreach ($file in Get-ChildItem $packsRoot -Recurse -File) {
    $rel = Get-Relative $file.FullName

    if ($rel -match '^packs/[^/]+/rules/([^/]+)$') {
        if ($Matches[1] -notmatch '^[a-z0-9][a-z0-9-]*\.mdc$') { $errors.Add("${rel}: rules/ holds only kebab-case .mdc files"); continue }
        $ruleCount++
        $fm = Read-Frontmatter $file.FullName
        if (-not $fm) { $errors.Add("${rel}: frontmatter must start on line 1 and close with ---"); continue }
        $f = $fm.Fields

        if (-not $f['description']) { $errors.Add("${rel}: missing description") }
        elseif ($f['description'] -match ': ') { $errors.Add("${rel}: description contains ': ', which breaks YAML; use an em dash") }
        elseif ($f['description'].Length -gt 120) { $warnings.Add("${rel}: description is over 120 characters; keep it under ~100") }

        if ($f['alwaysApply'] -eq 'true') {
            if ($rel -eq $routerRel) { $routerIsAlwaysOn = $true } else { $errors.Add("${rel}: only the router may set alwaysApply: true") }
        }
        elseif ($f['alwaysApply'] -ne 'false') { $errors.Add("${rel}: alwaysApply must be true or false") }

        if ($f['globs']) {
            if ($f['globs'] -match '[\[\]{}"'' ]') { $errors.Add("${rel}: globs must be one unquoted comma-separated line without spaces, [ ], or { }") }
            foreach ($glob in $f['globs'] -split ',') {
                if (-not $glob.StartsWith('**/')) { $errors.Add("${rel}: glob '$glob' must start with **/") }
            }
        }
        elseif ($f['alwaysApply'] -eq 'false') { $agentRequested++ }

        if ($fm.BodyLines -gt 60) { $warnings.Add("${rel}: body is $($fm.BodyLines) lines; aim for under ~50") }
    }
    elseif ($rel -match '^packs/([^/]+)/skills/([^/]+)/SKILL\.md$') {
        $pack = $Matches[1]
        $folder = $Matches[2]
        $fm = Read-Frontmatter $file.FullName
        if (-not $fm) { $errors.Add("${rel}: frontmatter must start on line 1 and close with ---"); continue }
        if ($folder -notmatch '^[a-z0-9-]{1,64}$') { $errors.Add("${rel}: skill folder must be lowercase letters, digits, and hyphens (max 64)") }
        if ($fm.Fields['name'] -ne $folder) { $errors.Add("${rel}: name '$($fm.Fields['name'])' must match its folder '$folder'") }
        $description = $fm.Fields['description']
        if (-not $description) { $errors.Add("${rel}: missing description") }
        elseif ($description.Length -gt 1024) { $errors.Add("${rel}: description is over 1024 characters") }
        if ($skillPacks.ContainsKey($folder)) {
            $errors.Add("Skill '$folder' exists in packs '$($skillPacks[$folder])' and '$pack'; skills share .cursor/skills/, so names must be unique")
        }
        else { $skillPacks[$folder] = $pack }
    }
    elseif ($rel -notmatch '^packs/[^/]+/skills/[^/]+/.+') {
        $warnings.Add("${rel}: not a rule or skill file, so the installer ignores it")
    }
}

if (-not $routerIsAlwaysOn) { $errors.Add("${routerRel}: the router must exist and set alwaysApply: true") }

# Router: pack table and skills line
$router = @(Get-Content $routerPath)
$routerPacks = @($router | ForEach-Object { if ($_ -match '^\| `([a-z0-9-]+)/` \|') { $Matches[1] } })
Compare-Names 'Router pack table' $routerPacks $packs 'pack'
$skillsLine = $router | Where-Object { $_ -like 'Skills*' } | Select-Object -First 1
$routerSkills = @()
if ($skillsLine) { $routerSkills = @([regex]::Matches($skillsLine, '`([a-z0-9-]+)`') | ForEach-Object { $_.Groups[1].Value }) }
Compare-Names 'Router skills line' $routerSkills @($skillPacks.Keys) 'skill'

# README: pack table in the install section, and the always-on numbers
$readme = @(Get-Content $readmePath)
$readmePacks = @()
$inInstall = $false
foreach ($line in $readme) {
    if ($line -match '^## ') { $inInstall = $line -eq '## Install into a project'; continue }
    if ($inInstall -and $line -match '^\| `([a-z0-9-]+)` \|') { $readmePacks += $Matches[1] }
}
Compare-Names 'README pack table' $readmePacks $packs 'pack'
$readmeRaw = $readme -join "`n"
$routerKb = ((Get-Item $routerPath).Length / 1024).ToString('0.0', [cultureinfo]::InvariantCulture)
if ($readmeRaw -notmatch "~$([regex]::Escape($routerKb)) KB") { $errors.Add("README token section should give the router size as ~$routerKb KB") }
if ($readmeRaw -notmatch "\b$agentRequested agent-requested\b") { $errors.Add("README token section should mention $agentRequested agent-requested rules") }

# Install examples (installer help and README) name only existing packs
$examples = (Get-Content (Join-Path $root 'install.ps1') -Raw) + "`n" + $readmeRaw
foreach ($m in [regex]::Matches($examples, '-Packs\s+([a-z0-9,-]+)')) {
    foreach ($p in $m.Groups[1].Value -split ',') {
        if ($p -and $p -notin $packs) { $errors.Add("Install example uses unknown pack '$p'") }
    }
}

# Cross-references like `laravel/caching.mdc` or `laravel/caching`, plus hosts and template names
$packPattern = ($packs | ForEach-Object { [regex]::Escape($_) }) -join '|'
$refRegex = "``($packPattern)/([a-z0-9-]+)(?:\.mdc)?``"
foreach ($file in Get-ChildItem $root -Recurse -File -Include *.md, *.mdc, *.template) {
    $rel = Get-Relative $file.FullName
    $text = Get-Content $file.FullName -Raw
    foreach ($m in [regex]::Matches($text, $refRegex)) {
        $target = Join-Path $packsRoot "$($m.Groups[1].Value)\rules\$($m.Groups[2].Value).mdc"
        if (-not (Test-Path $target)) { $errors.Add("${rel}: $($m.Value) points to no rule") }
    }
    foreach ($m in [regex]::Matches($text, '\b(?:\d{1,3}\.){3}\d{1,3}\b')) {
        if ($m.Value -notin '127.0.0.1', '0.0.0.0') { $errors.Add("${rel}: contains IP address $($m.Value); hosts belong in a project's copy, never the library") }
    }
}
foreach ($file in Get-ChildItem (Join-Path $root 'templates') -File -ErrorAction SilentlyContinue) {
    if ($file.Name -notlike '*.mdc.template') { $errors.Add("templates/$($file.Name): templates are named *.mdc.template so Cursor ignores them") }
}

# Test install of every pack into a temporary folder
$expected = @(Get-ChildItem $packsRoot -Recurse -File | Where-Object { (Get-Relative $_.FullName) -match '^packs/[^/]+/(rules|skills)/' }).Count
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('rules-library-' + [guid]::NewGuid())
New-Item -ItemType Directory $tmp | Out-Null
try {
    & (Join-Path $root 'install.ps1') -Target $tmp -Packs $packs *> $null
    $installed = @(Get-ChildItem (Join-Path $tmp '.cursor') -Recurse -File).Count
    if ($installed -ne $expected) { $errors.Add("Test install copied $installed files; expected $expected") }
}
catch { $errors.Add("Test install failed: $($_.Exception.Message)") }
finally { Remove-Item $tmp -Recurse -Force }

foreach ($w in $warnings) { Write-Warning $w }
Write-Host "$($packs.Count) packs, $ruleCount rules ($agentRequested agent-requested), $($skillPacks.Count) skills, router ~$routerKb KB"
if ($errors.Count) {
    foreach ($e in $errors) { Write-Host "ERROR: $e" -ForegroundColor Red }
    exit 1
}
Write-Host 'Library is valid.' -ForegroundColor Green
