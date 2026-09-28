[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$WorkspaceRoot,
    [string]$UserRoot = $env:USERPROFILE
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$warningList = [Collections.Generic.List[string]]::new()
$gitRootList = [Collections.Generic.List[object]]::new()
$entrypointList = [Collections.Generic.List[object]]::new()
$junctionList = [Collections.Generic.List[object]]::new()
$manifestPathList = [Collections.Generic.List[string]]::new()
$gitRootKeys = @{}
$entrypointKeys = @{}
$junctionKeys = @{}
$manifestPathKeys = @{}

function Add-AuditWarning([string]$Message) {
    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        $warningList.Add($Message) | Out-Null
    }
}

function Resolve-AuditRoot([string]$Path, [string]$Label) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "$Label is empty"
    }
    $absolute = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $absolute -PathType Container)) {
        throw "$Label is not an existing directory: $absolute"
    }
    return (Resolve-Path -LiteralPath $absolute).ProviderPath
}

function Test-ReparseItem([IO.FileSystemInfo]$Item) {
    return (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Get-LinkTargets([IO.FileSystemInfo]$Item) {
    $targets = @()
    if ($Item.PSObject.Properties['Target']) {
        $targets = @($Item.Target | ForEach-Object { [string]$_ } | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        } | Sort-Object -Unique)
    }
    return @($targets)
}

function Add-JunctionMetadata([IO.FileSystemInfo]$Item) {
    $key = $Item.FullName.ToLowerInvariant()
    if ($junctionKeys.ContainsKey($key)) { return }
    $junctionKeys[$key] = $true
    $linkType = $null
    if ($Item.PSObject.Properties['LinkType'] -and -not [string]::IsNullOrWhiteSpace([string]$Item.LinkType)) {
        $linkType = [string]$Item.LinkType
    }
    $junctionList.Add([pscustomobject][ordered]@{
        path = $Item.FullName
        item_type = $(if ($Item.PSIsContainer) { 'directory' } else { 'file' })
        link_type = $linkType
        targets = @(Get-LinkTargets $Item)
    }) | Out-Null
}

function Get-EntrypointKind([string]$Path) {
    if ([IO.Path]::GetFileName($Path) -ne 'skills') { return $null }
    $owner = [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($Path))
    if ($owner -in @('.agents', '.claude', '.codex')) {
        return $owner.TrimStart('.')
    }
    return $null
}

function Get-ScopeName([string]$Path) {
    $scopeRoot = Split-Path -Parent (Split-Path -Parent $Path)
    if ([string]::Equals($scopeRoot, $script:ResolvedUserRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return 'user'
    }
    if ([string]::Equals($scopeRoot, $script:ResolvedWorkspaceRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return 'workspace'
    }
    $prefix = $script:ResolvedWorkspaceRoot.TrimEnd('\') + '\'
    if ($scopeRoot.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $scopeRoot.Substring($prefix.Length).Replace('\', '/')
    }
    return $scopeRoot
}

function Add-Entrypoint([IO.FileSystemInfo]$Item) {
    $kind = Get-EntrypointKind $Item.FullName
    if ($null -eq $kind) { return }
    $key = $Item.FullName.ToLowerInvariant()
    if ($entrypointKeys.ContainsKey($key)) { return }
    $entrypointKeys[$key] = $true
    $isReparse = Test-ReparseItem $Item
    if ($isReparse) { Add-JunctionMetadata $Item }
    $linkType = $null
    if ($Item.PSObject.Properties['LinkType'] -and -not [string]::IsNullOrWhiteSpace([string]$Item.LinkType)) {
        $linkType = [string]$Item.LinkType
    }
    $entrypointList.Add([pscustomobject][ordered]@{
        path = $Item.FullName
        scope = Get-ScopeName $Item.FullName
        kind = $kind
        reparse_point = $isReparse
        link_type = $linkType
        targets = @(Get-LinkTargets $Item)
    }) | Out-Null
}

function Add-GitRoot([string]$Root, [IO.FileSystemInfo]$Marker) {
    $key = $Root.ToLowerInvariant()
    if ($gitRootKeys.ContainsKey($key)) { return }
    $gitRootKeys[$key] = $true
    $gitRootList.Add([pscustomobject][ordered]@{
        path = $Root
        marker = $Marker.FullName
        marker_type = $(if ($Marker.PSIsContainer) { 'directory' } else { 'file' })
    }) | Out-Null
}

function Add-ManifestPath([string]$Path) {
    $key = $Path.ToLowerInvariant()
    if ($manifestPathKeys.ContainsKey($key)) { return }
    $manifestPathKeys[$key] = $true
    $manifestPathList.Add($Path) | Out-Null
}

function Walk-Workspace([string]$Root) {
    $rootAttributes = [IO.File]::GetAttributes($Root)
    if (($rootAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        $rootItem = Get-Item -LiteralPath $Root -Force
        Add-JunctionMetadata $rootItem
        Add-AuditWarning "workspace_root is a reparse point; recursive inventory was skipped: $Root"
        return
    }

    $queue = [Collections.Generic.Queue[string]]::new()
    $queue.Enqueue($Root)
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        try {
            $entries = [IO.Directory]::EnumerateFileSystemEntries($current)
        } catch {
            Add-AuditWarning "unable to enumerate path: $current ($($_.Exception.Message))"
            continue
        }

        try {
            foreach ($path in $entries) {
                try {
                    $attributes = [IO.File]::GetAttributes($path)
                } catch {
                    Add-AuditWarning "unable to inspect path: $path ($($_.Exception.Message))"
                    continue
                }

                $isDirectory = (($attributes -band [IO.FileAttributes]::Directory) -ne 0)
                $isReparse = (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
                $name = [IO.Path]::GetFileName($path)

                if ($isReparse) {
                    $item = Get-Item -LiteralPath $path -Force
                    Add-JunctionMetadata $item
                    if ($isDirectory -and $null -ne (Get-EntrypointKind $path)) {
                        Add-Entrypoint $item
                    }
                    continue
                }

                if ($isDirectory) {
                    if ($name -eq '.git') {
                        Add-GitRoot $current (Get-Item -LiteralPath $path -Force)
                        continue
                    }
                    if ($null -ne (Get-EntrypointKind $path)) {
                        Add-Entrypoint (Get-Item -LiteralPath $path -Force)
                    }
                    $queue.Enqueue($path)
                    continue
                }

                if ($name -eq '.git') {
                    Add-GitRoot $current (Get-Item -LiteralPath $path -Force)
                    continue
                }
                if ($name -eq 'skills.json' -and [IO.Path]::GetFileName($current) -eq '.agents') {
                    Add-ManifestPath $path
                }
            }
        } catch {
            Add-AuditWarning "unable to enumerate path: $current ($($_.Exception.Message))"
        }
    }
}

function Inspect-UserEntrypoints([string]$Root) {
    foreach ($relative in @('.agents\skills', '.claude\skills', '.codex\skills')) {
        $path = Join-Path $Root $relative
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $item = Get-Item -LiteralPath $path -Force
        Add-Entrypoint $item
        if (Test-ReparseItem $item) { continue }
        try {
            foreach ($child in @(Get-ChildItem -LiteralPath $path -Force -ErrorAction Stop | Sort-Object Name, FullName)) {
                if (Test-ReparseItem $child) { Add-JunctionMetadata $child }
            }
        } catch {
            Add-AuditWarning "unable to enumerate user entrypoint: $path ($($_.Exception.Message))"
        }
    }
    $manifest = Join-Path $Root '.agents\skills.json'
    if (Test-Path -LiteralPath $manifest -PathType Leaf) { Add-ManifestPath $manifest }
}

function Read-JsonFile([string]$Path, [string]$Kind) {
    try {
        return (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        Add-AuditWarning "invalid $Kind JSON: $Path ($($_.Exception.Message))"
        return $null
    }
}

function Resolve-RecordedPath([object]$Value, [string]$BasePath) {
    if ($null -eq $Value) { return $null }
    $values = @($Value)
    if ($values.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$values[0])) {
        return $Value
    }
    $text = [string]$values[0]
    try {
        if ([IO.Path]::IsPathRooted($text)) { return [IO.Path]::GetFullPath($text) }
        return [IO.Path]::GetFullPath((Join-Path $BasePath $text))
    } catch {
        Add-AuditWarning "unable to resolve recorded path: $text"
        return $text
    }
}

function Get-ItemLinkSummary([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ exists = $false; reparse_point = $false; link_type = $null; targets = @() }
    }
    $item = Get-Item -LiteralPath $Path -Force
    $isReparse = Test-ReparseItem $item
    if ($isReparse) { Add-JunctionMetadata $item }
    $linkType = $null
    if ($item.PSObject.Properties['LinkType'] -and -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
        $linkType = [string]$item.LinkType
    }
    return [pscustomobject]@{
        exists = $true
        reparse_point = $isReparse
        link_type = $linkType
        targets = @(Get-LinkTargets $item)
    }
}

$script:ResolvedWorkspaceRoot = Resolve-AuditRoot $WorkspaceRoot 'WorkspaceRoot'
$script:ResolvedUserRoot = Resolve-AuditRoot $UserRoot 'UserRoot'
$sourceRoot = Join-Path $script:ResolvedWorkspaceRoot 'skill-repos'
$bodiesRoot = Join-Path $sourceRoot 'bodies'
$profilesRoot = Join-Path $sourceRoot 'profiles'
$registryPath = Join-Path $sourceRoot 'registry.json'
$controlScript = Join-Path $script:ResolvedWorkspaceRoot 'scripts\manage-skills.ps1'

Walk-Workspace $script:ResolvedWorkspaceRoot
Inspect-UserEntrypoints $script:ResolvedUserRoot

$registryData = $null
$registryValid = $false
if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
    $registryData = Read-JsonFile $registryPath 'registry'
    $registryValid = ($null -ne $registryData)
}
$controlPlanePresent = Test-Path -LiteralPath $controlScript -PathType Leaf
if (-not $controlPlanePresent) {
    Add-AuditWarning "no workspace Skill control plane was discovered; inventory remains read-only: $controlScript"
}

$bodyList = [Collections.Generic.List[object]]::new()
if (Test-Path -LiteralPath $bodiesRoot -PathType Container) {
    $bodyRootItem = Get-Item -LiteralPath $bodiesRoot -Force
    if (Test-ReparseItem $bodyRootItem) {
        Add-JunctionMetadata $bodyRootItem
        Add-AuditWarning "body pool is a reparse point and was not followed: $bodiesRoot"
    } else {
        foreach ($item in @(Get-ChildItem -LiteralPath $bodiesRoot -Directory -Force | Sort-Object Name, FullName)) {
            if (Test-ReparseItem $item) {
                Add-JunctionMetadata $item
                continue
            }
            $skillFile = Join-Path $item.FullName 'SKILL.md'
            if (Test-Path -LiteralPath $skillFile -PathType Leaf) {
                $bodyList.Add([pscustomobject][ordered]@{
                    name = $item.Name
                    path = $item.FullName
                    skill_file = $skillFile
                }) | Out-Null
            }
        }
    }
}

$profileList = [Collections.Generic.List[object]]::new()
if (Test-Path -LiteralPath $profilesRoot -PathType Container) {
    $profileRootItem = Get-Item -LiteralPath $profilesRoot -Force
    if (Test-ReparseItem $profileRootItem) {
        Add-JunctionMetadata $profileRootItem
        Add-AuditWarning "profiles root is a reparse point and was not followed: $profilesRoot"
    } else {
        foreach ($file in @(Get-ChildItem -LiteralPath $profilesRoot -Filter '*.json' -File -Force | Sort-Object Name, FullName)) {
            $profile = Read-JsonFile $file.FullName 'Profile'
            $profileList.Add([pscustomobject][ordered]@{
                name = [IO.Path]::GetFileNameWithoutExtension($file.Name)
                path = $file.FullName
                schema_version = $(if ($null -ne $profile -and $profile.PSObject.Properties['schema_version']) { $profile.schema_version } else { $null })
                skills = @($(if ($null -ne $profile -and $profile.PSObject.Properties['skills']) { @($profile.skills | ForEach-Object { [string]$_ } | Sort-Object -Unique) }))
            }) | Out-Null
        }
    }
}

$manifestList = [Collections.Generic.List[object]]::new()
foreach ($path in @($manifestPathList | Sort-Object -Unique)) {
    $manifest = Read-JsonFile $path 'Manifest'
    $manifestRoot = Split-Path -Parent (Split-Path -Parent $path)
    $manifestList.Add([pscustomobject][ordered]@{
        path = $path
        root = $manifestRoot
        schema_version = $(if ($null -ne $manifest -and $manifest.PSObject.Properties['schema_version']) { $manifest.schema_version } else { $null })
        profiles = @($(if ($null -ne $manifest -and $manifest.PSObject.Properties['profiles']) { @($manifest.profiles | ForEach-Object { [string]$_ } | Sort-Object -Unique) }))
        skills = @($(if ($null -ne $manifest -and $manifest.PSObject.Properties['skills']) { @($manifest.skills | ForEach-Object { [string]$_ } | Sort-Object -Unique) }))
    }) | Out-Null
}

$consumerByPath = @{}
if ($registryValid -and $registryData.PSObject.Properties['consumers']) {
    foreach ($consumer in @($registryData.consumers)) {
        if ($null -eq $consumer -or -not $consumer.PSObject.Properties['path']) { continue }
        $path = Resolve-RecordedPath $consumer.path $script:ResolvedWorkspaceRoot
        if ($path -isnot [string]) {
            Add-AuditWarning 'registry consumer path is not a single string'
            continue
        }
        $sourceBase = $(if ($registryData.PSObject.Properties['sourceRoot']) { Resolve-RecordedPath $registryData.sourceRoot $script:ResolvedWorkspaceRoot } else { $sourceRoot })
        if ($sourceBase -isnot [string]) { $sourceBase = $sourceRoot }
        $source = $(if ($consumer.PSObject.Properties['source']) { Resolve-RecordedPath $consumer.source $sourceBase } else { $null })
        $link = Get-ItemLinkSummary $path
        $consumerByPath[$path.ToLowerInvariant()] = [pscustomobject][ordered]@{
            path = $path
            name = $(if ($consumer.PSObject.Properties['name']) { [string]$consumer.name } else { [IO.Path]::GetFileName($path) })
            source = $source
            scope = $(if ($consumer.PSObject.Properties['scope']) { [string]$consumer.scope } else { $null })
            active = $(if ($consumer.PSObject.Properties['active']) { [bool]$consumer.active } else { $null })
            registered = $true
            entrypoint = Split-Path -Parent $path
            kind = Get-EntrypointKind (Split-Path -Parent $path)
            exists = $link.exists
            reparse_point = $link.reparse_point
            link_type = $link.link_type
            targets = @($link.targets)
        }
    }
}

foreach ($entrypoint in @($entrypointList)) {
    if ($entrypoint.reparse_point -or -not (Test-Path -LiteralPath $entrypoint.path -PathType Container)) { continue }
    try {
        $children = @(Get-ChildItem -LiteralPath $entrypoint.path -Directory -Force -ErrorAction Stop | Sort-Object Name, FullName)
    } catch {
        Add-AuditWarning "unable to enumerate consumers: $($entrypoint.path) ($($_.Exception.Message))"
        continue
    }
    foreach ($child in $children) {
        $key = $child.FullName.ToLowerInvariant()
        if ($consumerByPath.ContainsKey($key)) { continue }
        $isReparse = Test-ReparseItem $child
        if ($isReparse) { Add-JunctionMetadata $child }
        $linkType = $null
        if ($child.PSObject.Properties['LinkType'] -and -not [string]::IsNullOrWhiteSpace([string]$child.LinkType)) {
            $linkType = [string]$child.LinkType
        }
        $consumerByPath[$key] = [pscustomobject][ordered]@{
            path = $child.FullName
            name = $child.Name
            source = $null
            scope = $entrypoint.scope
            active = $null
            registered = $false
            entrypoint = $entrypoint.path
            kind = $entrypoint.kind
            exists = $true
            reparse_point = $isReparse
            link_type = $linkType
            targets = @(Get-LinkTargets $child)
        }
    }
}

$registrySummary = [pscustomobject][ordered]@{
    path = $registryPath
    present = (Test-Path -LiteralPath $registryPath -PathType Leaf)
    valid = $registryValid
    schema = $(if ($registryValid -and $registryData.PSObject.Properties['schema']) { $registryData.schema } else { $null })
    source_root = $(if ($registryValid -and $registryData.PSObject.Properties['sourceRoot']) { Resolve-RecordedPath $registryData.sourceRoot $script:ResolvedWorkspaceRoot } else { $null })
    body_records = $(if ($registryValid -and $registryData.PSObject.Properties['bodies']) { @($registryData.bodies).Count } else { 0 })
    consumer_records = $(if ($registryValid -and $registryData.PSObject.Properties['consumers']) { @($registryData.consumers).Count } else { 0 })
    conflicts = $(if ($registryValid -and $registryData.PSObject.Properties['conflicts']) { @($registryData.conflicts) } else { @() })
    control_script = $controlScript
    control_plane_present = $controlPlanePresent
}

$result = [pscustomobject][ordered]@{
    workspace_root = $script:ResolvedWorkspaceRoot
    git_roots = @($gitRootList | Sort-Object path)
    entrypoints = @($entrypointList | Sort-Object path)
    bodies = @($bodyList | Sort-Object path)
    registry = $registrySummary
    profiles = @($profileList | Sort-Object path)
    manifests = @($manifestList | Sort-Object path)
    consumers = @($consumerByPath.Values | Sort-Object path)
    junctions = @($junctionList | Sort-Object path)
    warnings = @($warningList | Sort-Object -Unique)
    evidence_level = 'structural'
}

$result | ConvertTo-Json -Depth 10
