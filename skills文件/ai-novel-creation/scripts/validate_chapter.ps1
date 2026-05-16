param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [int]$MinChars = 3000
)

$ErrorActionPreference = "Stop"

function Join-Chars([int[]]$Codes) {
    return -join ($Codes | ForEach-Object { [char]$_ })
}

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "File not found: $Path"
}

$text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

$chapterOpeningModeWord = Join-Chars @(0x672C, 0x7AE0, 0x5F00, 0x573A, 0x6A21, 0x5F0F)
$chapterEndWord = Join-Chars @(0x7B2C, 0x7AE0, 0x5B8C)
$body = $text
$metadataMatches = [regex]::Matches($text, "(?m)^\*\*$chapterOpeningModeWord")
if ($metadataMatches.Count -gt 0) {
    $lastMetadataMatch = $metadataMatches[$metadataMatches.Count - 1]
    $body = $text.Substring(0, $lastMetadataMatch.Index)
}
$endMatch = [regex]::Match($body, "(?m)^\*\*\[.*$chapterEndWord\]\*\*")
if ($endMatch.Success) {
    $body = $body.Substring(0, $endMatch.Index)
}
$chars = ($body -replace "\s", "").Length

$sceneWord = Join-Chars @(0x573A, 0x666F)
$approxWord = Join-Chars @(0x7EA6)
$bodyMeasuredWord = Join-Chars @(0x6B63, 0x6587, 0x5B9E, 0x6D4B, 0x5B57, 0x6570)
$validationWord = Join-Chars @(0x6545, 0x4E8B, 0x63A8, 0x8FDB, 0x9A8C, 0x8BC1)
$passWord = Join-Chars @(0x901A, 0x8FC7)
$colonPattern = "[:$([char]0xFF1A)]"

$scenePattern = "(?m)^#{2,4}\s+|^###\s+|^\s*$sceneWord\s*[0-9]+"
$sceneMatches = [regex]::Matches($body, $scenePattern)
$hasApproxCount = $text -match "$approxWord\s*3000|$approxWord\s*\d+\s*[^\d\s]"
$hasMeasuredCount = $text -match "$bodyMeasuredWord$colonPattern\s*\d+"
$hasValidation = $text -match "$validationWord$colonPattern\s*$passWord"

$issues = @()
if ($chars -lt $MinChars) {
    $issues += "Body chars below minimum: $chars / $MinChars"
}
if ($sceneMatches.Count -lt 4) {
    $issues += "Too few scene-like headings: $($sceneMatches.Count), expected at least 4"
}
if ($hasApproxCount) {
    $issues += "Approximate word-count claim found; use measured count only"
}
if (-not $hasMeasuredCount) {
    $issues += "Missing measured body-count metadata"
}
if (-not $hasValidation) {
    $issues += "Missing story-progress validation metadata"
}

[PSCustomObject]@{
    Path = (Resolve-Path -LiteralPath $Path).Path
    BodyChars = $chars
    SceneLikeHeadings = $sceneMatches.Count
    HasApproxCount = $hasApproxCount
    HasMeasuredCount = $hasMeasuredCount
    HasValidation = $hasValidation
    Passed = ($issues.Count -eq 0)
    Issues = $issues -join "; "
} | Format-List

if ($issues.Count -gt 0) {
    exit 1
}
