param([string]$GameRoot)
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-NoGame
$root = Resolve-Game $GameRoot
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.version -ne 'v1.0-beta') { throw 'Unexpected release version.' }
$payload = In-Game $PSScriptRoot $manifest.payload.path
if ((Get-Digest $payload) -ne $manifest.payload.sha256) { throw 'Release payload checksum mismatch; extract the ZIP again.' }
foreach ($inputFile in $manifest.required_inputs) {
    if ((Get-Digest (In-Game $root $inputFile.path)) -ne $inputFile.sha256) {
        throw "Unsupported or modified game input: $($inputFile.path). No changes made. See README.zh-CN.md."
    }
}
$statePath = In-Game $root 'zh-dub-mod-state/v1.0-beta.json'
if ([IO.File]::Exists($statePath)) {
    $old = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($old.payload_sha256 -ne $manifest.payload.sha256) { throw 'A different beta is installed. Uninstall it first.' }
    foreach ($row in $old.files) {
        if ((Get-Digest (In-Game $root $row.path)) -ne $row.after_sha256) { throw "Installed file changed: $($row.path)" }
    }
    Write-Host 'v1.0-beta is already installed; checksums match.'
    exit 0
}
$records = @()
foreach ($relative in $manifest.install_targets) {
    $target = In-Game $root $relative
    $before = Get-Digest $target
    $records += [pscustomobject]@{path=$relative; existed=($null -ne $before); before_sha256=$before; after_sha256=$manifest.payload.sha256}
}
foreach ($legacy in $manifest.legacy_overrides) {
    $target = In-Game $root $legacy.path
    $before = Get-Digest $target
    if ($null -eq $before) { continue }
    if ($before -ne $legacy.sha256) { throw "Unrecognized overlapping mod: $($legacy.path). No changes made." }
    $records += [pscustomobject]@{path=$legacy.path; existed=$true; before_sha256=$before; after_sha256=$null}
}
$backupRel = 'zh-dub-mod-backups/v1.0-beta/' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N')
$backup = In-Game $root $backupRel
foreach ($row in $records) {
    if ($row.existed) { Copy-Atomic (In-Game $root $row.path) (In-Game $backup $row.path) }
}
$receipt = [pscustomobject]@{version=$manifest.version; payload_sha256=$manifest.payload.sha256; backup_relative=$backupRel; files=$records; installed=$false; runtime_verified=$false}
Write-Json (In-Game $backup 'install-journal.json') $receipt
$changed = @()
try {
    foreach ($row in $records) {
        $target = In-Game $root $row.path
        if ($null -eq $row.after_sha256) { [IO.File]::Delete($target) }
        else { Copy-Atomic $payload $target }
        $changed += $row
        if ((Get-Digest $target) -ne $row.after_sha256) { throw "Install readback mismatch: $($row.path)" }
    }
    $receipt.installed = $true
    Write-Json $statePath $receipt
    Write-Json (In-Game $backup 'installed.json') $receipt
} catch {
    $failure = $_
    Restore-Records $root $backup $changed
    if ([IO.File]::Exists($statePath)) { [IO.File]::Delete($statePath) }
    throw $failure
}
Write-Host 'Installed v1.0-beta. Launch BlackOps.exe manually. Read KNOWN-ISSUES.zh-CN.md before testing.'
Write-Host "Rollback backup: $backup"
