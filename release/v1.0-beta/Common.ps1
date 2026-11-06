Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Digest([string]$Path) {
    if (-not [IO.File]::Exists($Path)) { return $null }
    $stream = [IO.File]::OpenRead($Path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-','').ToLowerInvariant() }
    finally { $stream.Dispose(); $algorithm.Dispose() }
}
function Assert-NoGame {
    if (Get-Process -Name BlackOps,BlackOpsMP -ErrorAction SilentlyContinue) {
        throw 'Close BlackOps / BlackOpsMP before installing or uninstalling.'
    }
}
function Resolve-Game([string]$Path) {
    if (-not $Path) { $Path = Read-Host 'Game folder containing BlackOps.exe' }
    $resolved = (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd('\','/')
    if (-not [IO.File]::Exists((Join-Path $resolved 'BlackOps.exe'))) { throw 'BlackOps.exe not found.' }
    return $resolved
}
function In-Game([string]$Root, [string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative)) { throw 'Absolute manifest target refused.' }
    $path = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    $prefix = $Root.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Target escapes game folder.' }
    $cursor = $path
    while ($cursor -and $cursor.Length -ge $Root.Length) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse target refused: $cursor"
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    return $path
}
function Copy-Atomic([string]$Source, [string]$Target) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Target)) | Out-Null
    $temp = $Target + '.zhdub-' + [guid]::NewGuid().ToString('N') + '.tmp'
    $previous = $temp + '.previous'
    try {
        [IO.File]::Copy($Source, $temp, $false)
        if ((Get-Digest $Source) -ne (Get-Digest $temp)) { throw 'Copy checksum mismatch.' }
        if ([IO.File]::Exists($Target)) { [IO.File]::Replace($temp, $Target, $previous) }
        else { [IO.File]::Move($temp, $Target) }
    } finally {
        if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
        if ([IO.File]::Exists($previous)) { [IO.File]::Delete($previous) }
    }
}
function Write-Json([string]$Path, $Value) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
    $temp = $Path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    [IO.File]::WriteAllText($temp, ($Value | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
    if ([IO.File]::Exists($Path)) {
        $previous = $temp + '.previous'
        [IO.File]::Replace($temp, $Path, $previous)
        [IO.File]::Delete($previous)
    }
    else { [IO.File]::Move($temp, $Path) }
}
function Restore-Records([string]$Root, [string]$Backup, $Records) {
    foreach ($row in $Records) {
        $target = In-Game $Root $row.path
        if ($row.existed) {
            $source = In-Game $Backup $row.path
            if ((Get-Digest $source) -ne $row.before_sha256) { throw "Backup checksum mismatch: $($row.path)" }
            Copy-Atomic $source $target
        } elseif ([IO.File]::Exists($target)) { [IO.File]::Delete($target) }
        if ((Get-Digest $target) -ne $row.before_sha256) { throw "Restore verification failed: $($row.path)" }
    }
}
