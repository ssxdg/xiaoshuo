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
$causalValidationWord = Join-Chars @(0x56E0, 0x679C, 0x94FE, 0x9A8C, 0x8BC1)
$protagonistCostWord = Join-Chars @(0x4E3B, 0x89D2, 0x4ED8, 0x51FA, 0x4EE3, 0x4EF7)
$nextHookWord = Join-Chars @(0x4E0B, 0x4E00, 0x7AE0, 0x94A9, 0x5B50)
$passWord = Join-Chars @(0x901A, 0x8FC7)
$emptyWord = Join-Chars @(0x65E0)
$temporaryEmptyWord = Join-Chars @(0x6682, 0x65E0)
$notHaveWord = Join-Chars @(0x6CA1, 0x6709)
$pendingWord = Join-Chars @(0x5F85, 0x5B9A)
$colonPattern = "[:$([char]0xFF1A)]"
$specificValuePattern = "(?!\s*(\{|$emptyWord|$temporaryEmptyWord|$notHaveWord|$pendingWord))\s*[^\r\n\*]+"

$scenePattern = "(?m)^#{2,4}\s+|^###\s+|^\s*$sceneWord\s*[0-9]+"
$sceneMatches = [regex]::Matches($body, $scenePattern)
$hasApproxCount = $text -match "$approxWord\s*3000|$approxWord\s*\d+\s*[^\d\s]"
$hasMeasuredCount = $text -match "$bodyMeasuredWord$colonPattern\s*\d+"
$hasValidation = $text -match "$validationWord$colonPattern\s*$passWord"
# 新增的三项校验用于约束章节不能只满足字数，还要留下可检查的逻辑闭环。
# 因果链验证要求作者明确确认场景之间不是并列清单，而是由前一场结果触发后一场行动。
$escapedCausalValidationWord = [regex]::Escape($causalValidationWord)
$escapedPassWord = [regex]::Escape($passWord)
$hasCausalValidation = [regex]::IsMatch([string]$text, "$escapedCausalValidationWord$colonPattern\s*$escapedPassWord")
# 主角代价必须写出具体内容，不能用“无”“待定”或模板占位符逃避人物行动后果。
$escapedProtagonistCostWord = [regex]::Escape($protagonistCostWord)
$hasProtagonistCost = [regex]::IsMatch([string]$text, "$escapedProtagonistCostWord$colonPattern$specificValuePattern")
# 下一章钩子必须写出具体内容，保证章节结尾能自然牵引后续情节。
$escapedNextHookWord = [regex]::Escape($nextHookWord)
$hasNextHook = [regex]::IsMatch([string]$text, "$escapedNextHookWord$colonPattern$specificValuePattern")

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
if (-not $hasCausalValidation) {
    $issues += "Missing causal-chain validation metadata"
}
if (-not $hasProtagonistCost) {
    $issues += "Missing specific protagonist-cost metadata"
}
if (-not $hasNextHook) {
    $issues += "Missing specific next-chapter-hook metadata"
}

[PSCustomObject]@{
    Path = (Resolve-Path -LiteralPath $Path).Path
    BodyChars = $chars
    SceneLikeHeadings = $sceneMatches.Count
    HasApproxCount = $hasApproxCount
    HasMeasuredCount = $hasMeasuredCount
    HasValidation = $hasValidation
    HasCausalValidation = $hasCausalValidation
    HasProtagonistCost = $hasProtagonistCost
    HasNextHook = $hasNextHook
    Passed = ($issues.Count -eq 0)
    Issues = $issues -join "; "
} | Format-List

if ($issues.Count -gt 0) {
    exit 1
}
