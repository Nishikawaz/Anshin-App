$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$repoDir = $rootDir

while ($true) {
  if (Test-Path (Join-Path $repoDir ".git")) {
    break
  }
  $parent = Split-Path -Parent $repoDir
  if ($parent -eq $repoDir) {
    Write-Error "setup-hooks: .git directory not found in current or parent folders."
  }
  $repoDir = $parent
}

$hooksDir = Join-Path $repoDir ".git/hooks"
$sourceDir = Join-Path $rootDir "hooks"

New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null

$hookFiles = @("pre-commit", "pre-push", "commit-msg")

foreach ($hook in $hookFiles) {
  $src = Join-Path $sourceDir $hook
  $dst = Join-Path $hooksDir $hook
  Copy-Item -Force $src $dst
  Write-Host "setup-hooks: installed $hook"
}

Write-Host "setup-hooks: done."
