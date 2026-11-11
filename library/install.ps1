<#
.SYNOPSIS
Copies rule packs (and their skills) into a project's .cursor folder. The core pack is always included.
Packs are discovered from the packs/ folder, so a new pack folder is installable without editing this script.

.EXAMPLE
.\install.ps1 -List

.EXAMPLE
.\install.ps1 -Target D:\Projects\shop -Packs laravel,qwik,admin,public-site

.EXAMPLE
.\install.ps1 -Target D:\Projects\portal -Packs laravel,nuxt,admin

.EXAMPLE
.\install.ps1 -Target D:\Projects\wp-plugin -Packs wordpress

.EXAMPLE
.\install.ps1 -Target D:\Projects\mobile-app -Packs react-native

.EXAMPLE
.\install.ps1 -Target D:\Projects\shop -Packs laravel -Force   # overwrite files already in the project

.EXAMPLE
.\install.ps1 -Target D:\Projects\sandbox -All -Force   # every pack
#>
[CmdletBinding(DefaultParameterSetName = 'Install')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Install')]
    [Parameter(Mandatory, ParameterSetName = 'All')]
    [string]$Target,
    [Parameter(ParameterSetName = 'Install')][string[]]$Packs = @(),
    [Parameter(Mandatory, ParameterSetName = 'All')][switch]$All,
    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'All')]
    [switch]$Force,
    [Parameter(Mandatory, ParameterSetName = 'List')][switch]$List
)

$ErrorActionPreference = 'Stop'
$packsRoot = Join-Path $PSScriptRoot 'packs'
$available = Get-ChildItem $packsRoot -Directory | Select-Object -ExpandProperty Name

if ($List) {
    $router = Get-Content (Join-Path $packsRoot 'core\rules\00-router.mdc')
    foreach ($pack in $available) {
        $row = $router | Where-Object { $_ -match "^\| ``$([regex]::Escape($pack))/`` \|" } | Select-Object -First 1
        [pscustomobject]@{
            Pack         = $pack
            Rules        = @(Get-ChildItem (Join-Path $packsRoot "$pack\rules") -Filter *.mdc -ErrorAction SilentlyContinue).Count
            Skills       = @(Get-ChildItem (Join-Path $packsRoot "$pack\skills") -Directory -ErrorAction SilentlyContinue).Count
            'Applies to' = if ($row) { ($row -split '\|')[2].Trim() } else { '' }
        }
    }
    return
}

# `powershell -File` passes a comma-separated pack list as one string, so split on commas as well.
$requested = if ($All) { $available } else { $Packs | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
$selected = @('core') + @($requested) | Select-Object -Unique

$unknown = $selected | Where-Object { $_ -notin $available }
if ($unknown) { throw "Unknown pack(s): $($unknown -join ', '). Available: $($available -join ', ')" }
if (-not (Test-Path $Target -PathType Container)) { throw "Target folder not found: $Target" }

# Existing files are kept unless -Force, so project-specific edits (e.g. a filled-in deploy skill) survive re-installs.
function Copy-Tree([string]$Source, [string]$Destination) {
    if (-not (Test-Path $Source)) { return }
    $root = (Resolve-Path $Source).Path
    Get-ChildItem $root -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($root.Length).TrimStart('\')
        $out = Join-Path $Destination $relative
        if ((Test-Path $out) -and -not $Force) {
            Write-Warning "Skipped (already exists): $out"
            return
        }
        New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
        Copy-Item $_.FullName $out -Force
        Write-Host "Copied $relative -> $out"
    }
}

# Pack rule folders belong to the library, so a file the library no longer has was renamed, moved, or removed.
function Write-StaleRules([string]$Source, [string]$Destination) {
    if (-not (Test-Path $Destination)) { return }
    Get-ChildItem $Destination -File | Where-Object { -not (Test-Path (Join-Path $Source $_.Name)) } | ForEach-Object {
        Write-Warning "Not in the library anymore (renamed, moved, or removed); delete it unless it is a project addition: $($_.FullName)"
    }
}

foreach ($pack in $selected) {
    $rulesSource = Join-Path $packsRoot "$pack\rules"
    $rulesTarget = Join-Path $Target ".cursor\rules\$pack"
    Copy-Tree $rulesSource $rulesTarget
    Write-StaleRules $rulesSource $rulesTarget
    Copy-Tree (Join-Path $packsRoot "$pack\skills") (Join-Path $Target '.cursor\skills')
}

Write-Host "Installed packs: $($selected -join ', ')"
