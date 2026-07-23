[CmdletBinding()]
param(
  [string]$RepoRoot,
  [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Join-Path $PSScriptRoot ".."
}

function Resolve-RepositoryRoot([string]$Path) {
  $resolved = (Resolve-Path -LiteralPath $Path).Path
  $gitRoot = (& git -C $resolved rev-parse --show-toplevel).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "'$resolved' is not inside a Git repository."
  }
  return $gitRoot
}

function Get-LineCount([string]$Path) {
  $content = Get-Content -LiteralPath $Path
  return @($content).Count
}

$root = Resolve-RepositoryRoot $RepoRoot
$trackedFiles = @(& git -C $root ls-files -- "*.mbt")
if ($LASTEXITCODE -ne 0) {
  throw "Could not list tracked MoonBit sources."
}

$files = foreach ($relativePath in $trackedFiles) {
  $normalized = $relativePath.Replace("\", "/")
  $category = if ($normalized -like "src/*") {
    if ($normalized -like "*_test.mbt") { "source-test" } else { "source" }
  } elseif ($normalized -like "benchmarks/*") {
    if ($normalized -like "*_test.mbt") { "benchmark-test" } else { "benchmark" }
  } else {
    "other"
  }

  [pscustomobject]@{
    path = $normalized
    category = $category
    lines = Get-LineCount (Join-Path $root $relativePath)
  }
}

$categories = foreach ($category in @(
  "source",
  "source-test",
  "benchmark",
  "benchmark-test",
  "other"
)) {
  $members = @($files | Where-Object { $_.category -eq $category })
  $lineTotal = if ($members.Count -gt 0) {
    [int]($members | Measure-Object -Property lines -Sum).Sum
  } else {
    0
  }
  [pscustomobject]@{
    category = $category
    files = $members.Count
    lines = $lineTotal
  }
}

$totalLines = if ($files.Count -gt 0) {
  [int]($files | Measure-Object -Property lines -Sum).Sum
} else {
  0
}

$report = [pscustomobject]@{
  repository = $root
  inclusion = "Tracked *.mbt files only; working-tree-only and ignored files are excluded."
  exclusions = "Generated *.mbti interfaces, dependencies, build outputs, and non-MoonBit files are excluded. *_test.mbt files are reported separately."
  categories = $categories
  total_files = $files.Count
  total_lines = $totalLines
}

if ($AsJson) {
  $report | ConvertTo-Json -Depth 4
} else {
  "MoonBit line-count report"
  "Repository: $($report.repository)"
  "Inclusion: $($report.inclusion)"
  "Exclusions: $($report.exclusions)"
  $report.categories | Format-Table -AutoSize | Out-String | Write-Output
  "Total: $($report.total_files) files, $($report.total_lines) lines"
}
