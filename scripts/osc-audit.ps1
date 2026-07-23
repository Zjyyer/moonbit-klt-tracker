[CmdletBinding()]
param(
  [string]$RepoRoot,
  [switch]$AllowNonMain,
  [switch]$SkipQualityGates,
  [switch]$CheckRemoteDefault
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Join-Path $PSScriptRoot ".."
}

function Invoke-Git([string[]]$Arguments) {
  $output = & git -C $root @Arguments 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed: $($output | Out-String)"
  }
  return @($output)
}

function Add-Check([string]$Name, [bool]$Passed, [string]$Evidence, [bool]$Required = $true) {
  $status = if ($Passed) { "pass" } elseif ($Required) { "fail" } else { "pending" }
  $checks.Add([pscustomobject]@{ check = $Name; status = $status; evidence = $Evidence })
  if ($Required -and -not $Passed) {
    $failures.Add("${Name}: $Evidence")
  }
}

function Invoke-QualityGate([string]$Name, [string]$Command, [string[]]$Arguments) {
  $previousErrorAction = $ErrorActionPreference
  try {
    # MoonBit writes normal progress messages to stderr. Keep them as evidence
    # and use the process exit status, rather than treating the stream alone as
    # a PowerShell failure.
    $ErrorActionPreference = "Continue"
    $output = & $Command @Arguments 2>&1
    $passed = $LASTEXITCODE -eq 0
  } finally {
    $ErrorActionPreference = $previousErrorAction
  }
  $evidence = if ($passed) { "passed" } else { ($output | Out-String).Trim() }
  Add-Check $Name $passed $evidence
}

$root = (Resolve-Path -LiteralPath $RepoRoot).Path
$gitRoot = (& git -C $root rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) {
  throw "RepoRoot must be inside a Git repository."
}
$gitRoot = (Resolve-Path -LiteralPath $gitRoot).Path
if ($gitRoot -ne $root) {
  throw "RepoRoot must be the Git repository root."
}

$checks = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[string]]::new()

& git -C $root show-ref --verify --quiet refs/heads/main
$mainRefExists = $LASTEXITCODE -eq 0
Add-Check "Local main branch exists" $mainRefExists "refs/heads/main"

$currentBranch = (Invoke-Git @("branch", "--show-current") | Select-Object -First 1).Trim()
$onMain = $currentBranch -eq "main"
if ($AllowNonMain) {
  Add-Check "Candidate checked out on main" $onMain "current branch: $currentBranch (allowed for development run)" $false
} else {
  Add-Check "Candidate checked out on main" $onMain "current branch: $currentBranch"
}

$authors = @(Invoke-Git @("log", "--format=%an <%ae>") | Where-Object { $_.Trim() -ne "" } | Sort-Object -Unique)
Add-Check "Single actual Git author identity" ($authors.Count -eq 1) ($authors -join "; ")

$commitCount = [int](Invoke-Git @("rev-list", "--count", "HEAD") | Select-Object -First 1)
Add-Check "At least 10 committed revisions" ($commitCount -ge 10) "history count: $commitCount; inspect commit contents manually for meaningful scope"

$licensePath = Join-Path $root "LICENSE"
$licenseIsApache = (Test-Path -LiteralPath $licensePath -PathType Leaf) -and ((Get-Content -Raw -LiteralPath $licensePath) -match "Apache License")
Add-Check "Apache-2.0 license" $licenseIsApache "LICENSE"
Add-Check "README exists" (Test-Path -LiteralPath (Join-Path $root "README.md") -PathType Leaf) "README.md"
Add-Check "CI workflow exists" (Test-Path -LiteralPath (Join-Path $root ".github/workflows/check.yml") -PathType Leaf) ".github/workflows/check.yml"

$lineCountScript = Join-Path $root "scripts/line-count.ps1"
$lineCount = & $lineCountScript -RepoRoot $root -AsJson | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
  throw "MoonBit line-count script failed."
}
Add-Check "MoonBit source inventory" ($lineCount.total_files -gt 0) "$($lineCount.total_files) tracked .mbt files; $($lineCount.total_lines) lines; see scripts/line-count.ps1 inclusion rules"

if ($CheckRemoteDefault) {
  $remote = (Invoke-Git @("remote", "get-url", "origin") | Select-Object -First 1).Trim()
  $remoteHead = Invoke-Git @("ls-remote", "--symref", "origin", "HEAD")
  $remoteIsMain = @($remoteHead | Where-Object { $_ -match "^ref: refs/heads/main\s+HEAD$" }).Count -eq 1
  Add-Check "Remote origin default branch" $remoteIsMain "origin: $remote"
} else {
  Add-Check "Remote origin default branch" $false "not checked locally; run -CheckRemoteDefault after publishing" $false
}

if ($SkipQualityGates) {
  Add-Check "MoonBit quality gates" $false "skipped by -SkipQualityGates" $false
} else {
  Invoke-QualityGate "moon fmt --check" "moon" @("fmt", "--check")
  Invoke-QualityGate "moon check --target all --deny-warn" "moon" @("check", "--target", "all", "--deny-warn")
  Invoke-QualityGate "moon test --target all --deny-warn" "moon" @("test", "--target", "all", "--deny-warn")
  Invoke-QualityGate "moon info" "moon" @("info")
  Invoke-QualityGate "Generated-interface clean diff" "git" @("-C", $root, "diff", "--exit-code")
}

$checks | Format-Table -AutoSize | Out-String | Write-Output
if ($failures.Count -gt 0) {
  throw "OSC audit failed:`n$($failures -join "`n")"
}

"OSC local audit passed. This verifies local repository evidence only; remote default-branch status is checked only with -CheckRemoteDefault."
