param([string]$GameRoot)
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-NoGame
$root = Resolve-Game $GameRoot
$statePath = In-Game $root 'zh-dub-mod-state/v1.0-beta.json'
if (-not [IO.File]::Exists($statePath)) { throw 'No v1.0-beta installation receipt found.' }
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($state.version -ne 'v1.0-beta') { throw 'Wrong installation receipt.' }
$backup = In-Game $root $state.backup_relative
foreach ($row in $state.files) {
    if ((Get-Digest (In-Game $root $row.path)) -ne $row.after_sha256) {
        throw "File changed after installation; refusing to overwrite your changes: $($row.path)"
    }
    if ($row.existed -and (Get-Digest (In-Game $backup $row.path)) -ne $row.before_sha256) {
        throw "Backup missing or modified: $($row.path)"
    }
}
Restore-Records $root $backup $state.files
$state.installed = $false
Write-Json (In-Game $backup 'uninstalled.json') $state
[IO.File]::Delete($statePath)
Write-Host 'Uninstalled v1.0-beta; pre-install mod files restored. Backups retained.'
