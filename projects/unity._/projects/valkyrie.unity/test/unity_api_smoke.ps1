# Validates Valkyrie Unity CLR binding targets against Unity 6 managed assemblies.
param(
    [string]$UnityEditorRoot = "E:\UnityEditor\6000.2.6f2"
)

$ErrorActionPreference = "Stop"
$engineDir = Join-Path $UnityEditorRoot "Editor\Data\Managed\UnityEngine"
$editorDir = Join-Path $UnityEditorRoot "Editor\Data\Managed\UnityEditor"

$modules = @(
    Join-Path $engineDir "UnityEngine.CoreModule.dll",
    Join-Path $engineDir "UnityEngine.UnityWebRequestModule.dll",
    Join-Path $editorDir "UnityEditor.CoreModule.dll"
)

$bindings = @(
    @{ Type = "UnityEngine.Application"; Member = "get_dataPath"; Module = "UnityEngine.CoreModule.dll" },
    @{ Type = "UnityEngine.Debug"; Member = "Log"; Module = "UnityEngine.CoreModule.dll" },
    @{ Type = "UnityEngine.Networking.UnityWebRequest"; Member = "Get"; Module = "UnityEngine.UnityWebRequestModule.dll" },
    @{ Type = "UnityEditor.EditorApplication"; Member = "get_dataPath"; Module = "UnityEditor.CoreModule.dll" }
)

function Find-Member($type, [string]$memberName) {
    $flags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Instance
    if ($memberName.StartsWith("get_") -or $memberName.StartsWith("set_")) {
        $prop = $type.GetProperty($memberName.Substring(4), $flags)
        if ($null -ne $prop) { return $prop }
    }
    return $type.GetMethod($memberName, $flags)
}

Write-Host "Unity 6 root: $UnityEditorRoot"
$passed = 0
$failed = 0

foreach ($binding in $bindings) {
    $modulePath = Join-Path $(if ($binding.Module.StartsWith("UnityEditor")) { $editorDir } else { $engineDir }) $binding.Module
    if (-not (Test-Path $modulePath)) {
        Write-Host "FAIL  missing module $($binding.Module)"
        $failed++
        continue
    }
    $asm = [System.Reflection.Assembly]::LoadFrom($modulePath)
    $type = $asm.GetType($binding.Type, $true, $false)
    if ($null -eq $type) {
        Write-Host "FAIL  $($binding.Type) in $($binding.Module)"
        $failed++
        continue
    }
    $member = Find-Member $type $binding.Member
    if ($null -eq $member) {
        Write-Host "FAIL  $($binding.Type)::$($binding.Member)"
        $failed++
        continue
    }
    Write-Host "OK    $($binding.Type)::$($binding.Member)  [$($binding.Module)]"
    $passed++
}

Write-Host ""
Write-Host "unity-api-smoke: $passed passed, $failed failed"
if ($failed -gt 0) { exit 1 }
exit 0
