# ============================================================================
# ScriptHub.Core.ps1 - Logic layer (no UI, no CSV persistence)
# Part of ScriptHub. Loaded by ScriptHub.UI.ps1 - do not run this file alone.
# Author: Ismael Najera
#
# The catalog is code-based: scripts live in ScriptHub.Catalog.ps1.
# Nothing is written to %APPDATA%; the tool is read-only at runtime.
# ============================================================================

# === GLOBAL CONFIG ===
$global:ScriptHubConfig = [ordered]@{
    Version         = '3.0'
    Author          = 'Ismael Najera'
    # Intake and feedback endpoints published on the ScriptHub site.
    # Replace the URLs below with the real Forms / List links.
    SiteUrl         = 'https://<TenantName>.sharepoint.com/sites/<ScriptHubSite>'
    RequestFormUrl  = 'https://<TenantName>.sharepoint.com/sites/<ScriptHubSite>/SitePages/Submit-a-Script.aspx'
    FeedbackFormUrl = 'https://<TenantName>.sharepoint.com/sites/<ScriptHubSite>/SitePages/Feedback.aspx'
    TempFolder      = (Join-Path $env:TEMP 'ScriptHub')
}

$global:Commands = [System.Collections.ArrayList]::new()

# === HELPER: Deterministic short ID from the command name ===
function Get-CmdId {
    param([string]$Name)
    $md5   = [System.Security.Cryptography.MD5]::Create()
    $bytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Name))
    return ([System.BitConverter]::ToString($bytes) -replace '-','').Substring(0,8).ToLower()
}

# === HELPER: Command entry object ===
function New-CmdEntry {
    param(
        [string]$N,     # Name
        [string]$Cat,   # Category
        [string]$Sub,   # SubCategory
        [string]$Desc,  # Description
        [string]$Scr,   # Script body
        [string]$PSV,   # PowerShell version
        [string]$Tags,  # Comma separated tags
        [string]$Notes, # Notes / warnings
        [string]$Id
    )
    [PSCustomObject]@{
        Id          = $(if ($Id) { $Id } else { Get-CmdId -Name $N })
        Name        = $N
        Category    = $Cat
        SubCategory = $Sub
        Description = $Desc
        Script      = $Scr
        PSVersion   = $PSV
        Tags        = $Tags
        Notes       = $Notes
    }
}

# === Load the catalog into memory (in-memory only) ===
function Initialize-ScriptHub {
    $global:Commands.Clear()
    foreach ($cmd in (Get-ScriptHubCatalog)) { [void]$global:Commands.Add($cmd) }
    return $global:Commands.Count
}

# === Filtering / search ===
function Select-ScriptHubCommand {
    param(
        [string]$SearchText = '',
        [string]$Category   = 'All',
        [string]$PSVersion  = 'All'
    )
    $res = $global:Commands
    if ($Category  -ne 'All') { $res = $res | Where-Object { $_.Category -eq $Category } }
    if ($PSVersion -ne 'All') { $res = $res | Where-Object { $_.PSVersion -like "*$PSVersion*" } }
    if ($SearchText.Trim() -ne '') {
        $s = $SearchText.ToLower()
        $res = $res | Where-Object {
            "$($_.Name) $($_.Description) $($_.Script) $($_.Tags) $($_.Category) $($_.SubCategory) $($_.Notes)".ToLower().Contains($s)
        }
    }
    return @($res)
}

function Get-ScriptHubCommandById {
    param([string]$Id)
    return ($global:Commands | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
}

function Get-ScriptHubCategory {
    return @('All') + @($global:Commands | ForEach-Object { $_.Category } | Sort-Object -Unique)
}

# === Placeholder detection: <Something> tokens inside a script body ===
function Get-ScriptHubPlaceholder {
    param([string]$ScriptText)
    $list = [System.Collections.Generic.List[string]]::new()
    $pattern = '<([A-Za-z][A-Za-z0-9_\- ]{1,40})>'
    foreach ($m in [regex]::Matches($ScriptText, $pattern)) {
        $ph = $m.Groups[1].Value.Trim()
        if (-not $list.Contains($ph)) { $list.Add($ph) }
    }
    return $list
}

function Expand-ScriptHubPlaceholder {
    param([string]$ScriptText, [hashtable]$Values)
    $out = $ScriptText
    foreach ($key in $Values.Keys) {
        $val = [string]$Values[$key]
        if ($val -ne '') {
            $token = [regex]::Escape("<$key>")
            $out = $out -replace $token, $val
        }
    }
    return $out
}

# === Export a script to a .ps1 file ===
function Save-ScriptHubScript {
    param([string]$ScriptText, [string]$Path)
    $ScriptText | Set-Content -Path $Path -Encoding UTF8
    return $Path
}

# === Run a script in a new PowerShell window ===
function Invoke-ScriptHubScript {
    param([string]$ScriptText, [string]$CmdName)
    $dir = $global:ScriptHubConfig.TempFolder
    if (-not (Test-Path $dir)) { [void](New-Item -Path $dir -ItemType Directory -Force) }
    $safeName = $CmdName -replace '[^\w\-]', '_'
    $stamp    = Get-Date -Format 'yyyyMMdd_HHmmss'
    $file     = Join-Path $dir ($safeName + '_' + $stamp + '.ps1')
    $ScriptText | Set-Content -Path $file -Encoding UTF8
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$file`""
    return $file
}

# === Build a ready-to-paste catalog block for an approved submission ===
# The reviewer pastes the returned text into ScriptHub.Catalog.ps1.
function New-ScriptHubCatalogEntry {
    param(
        [string]$Name,
        [string]$Category,
        [string]$SubCategory,
        [string]$Description,
        [string]$ScriptText,
        [string]$PSVersion,
        [string]$Tags,
        [string]$Notes
    )
    $bt = '`'          # backtick used as PowerShell line continuation
    $q  = '"'
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('    $d += New-CmdEntry -N ' + $q + $Name + $q + ' -Cat ' + $q + $Category + $q + ' -Sub ' + $q + $SubCategory + $q + ' ' + $bt)
    [void]$sb.AppendLine('        -Desc ' + $q + $Description + $q + ' ' + $bt)
    [void]$sb.AppendLine('        -PSV ' + $q + $PSVersion + $q + ' -Tags ' + $q + $Tags + $q + ' ' + $bt)
    [void]$sb.AppendLine('        -Notes ' + $q + $Notes + $q + ' ' + $bt)
    [void]$sb.AppendLine("        -Scr @'")
    [void]$sb.AppendLine($ScriptText.TrimEnd())
    [void]$sb.AppendLine("'@")
    return $sb.ToString()
}

# === Open the intake / feedback pages published on the ScriptHub site ===
function Open-ScriptHubRequestForm  { Start-Process $global:ScriptHubConfig.RequestFormUrl }
function Open-ScriptHubFeedbackForm { Start-Process $global:ScriptHubConfig.FeedbackFormUrl }
