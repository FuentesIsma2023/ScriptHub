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
    PowerShell7Url  = 'https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows'
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

function Get-ScriptHubTeamForEntry {
    param(
        [string]$Name,
        [string]$Category,
        [string]$ScriptText
    )
    if ($Category -eq 'Teams' -or $Name -match 'Teams') { return 'Teams' }
    if ($Name -match 'all M365 workloads') { return 'Microsoft 365' }
    if ($Category -eq 'PnP Registration' -or $Name -match 'PnP') { return 'PnP PowerShell' }
    if ($Category -eq 'Exchange' -or $Name -match 'Exchange|Mailbox|Message Trace|M365 Group') { return 'Exchange Online' }
    if ($Category -eq 'Entra ID' -or $Name -match 'Entra ID|Azure AD') { return 'Entra ID' }
    if ($Category -eq 'Azure' -or $Name -match '^Azure') { return 'Azure' }
    if ($Category -eq 'Purview' -or $Name -match 'Audit Log') { return 'Purview' }
    if ($Category -eq 'OneDrive' -or $Name -match 'OneDrive') { return 'OneDrive' }
    if ($Name -match 'Graph PowerShell') { return 'Microsoft Graph' }
    return 'SharePoint'
}

function Get-ScriptHubDependencies {
    param([psobject]$Command)

    $scriptText = [string]$Command.Script
    $modules = [System.Collections.Generic.List[string]]::new()
    $addModule = {
        param([string]$Name)
        if (-not $modules.Contains($Name)) { [void]$modules.Add($Name) }
    }

    if ($scriptText -match '(?i)\b(PnP|Connect-PnP|Get-PnP|Set-PnP|Add-PnP|Remove-PnP|Copy-PnP|Move-PnP|Restore-PnP|New-PnP)') {
        & $addModule 'PnP.PowerShell'
    }
    if ($scriptText -match '(?i)\b(Connect-SPO|Get-SPO|Set-SPO|Add-SPO|Remove-SPO|Request-SPO|Install-Module Microsoft\.Online\.SharePoint)') {
        & $addModule 'Microsoft.Online.SharePoint.PowerShell'
    }
    if ($scriptText -match '(?i)\b(Connect-ExchangeOnline|Get-Mailbox|Set-Mailbox|Add-Mailbox|Remove-Mailbox|Get-MessageTrace|Search-UnifiedAuditLog|Get-UnifiedGroup|Add-UnifiedGroup|Set-UnifiedGroup)') {
        & $addModule 'ExchangeOnlineManagement'
    }
    if ($scriptText -match '(?i)\b(Connect-MicrosoftTeams|Get-Team|Set-Team|Add-Team|Remove-Team|Grant-Cs|Get-Cs)') {
        & $addModule 'MicrosoftTeams'
    }
    if ($scriptText -match '(?i)\b(Connect-MgGraph|Get-Mg|Set-Mg|New-Mg|Remove-Mg|Install-Module Microsoft\.Graph)') {
        & $addModule 'Microsoft.Graph'
    }
    if ($scriptText -match '(?i)\b(Connect-AzAccount|Get-Az|Set-Az|New-Az|Remove-Az|Install-Module -Name Az)') {
        & $addModule 'Az'
    }

    [PSCustomObject]@{
        PowerShellVersion = $Command.PSVersion
        RequiresPowerShell7 = ([string]$Command.PSVersion -match '(?i)^\s*7(?:\s*\(recommended\))?\s*$')
        Modules = @($modules)
        PowerShell7Url = 'https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows'
    }
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
        [string]$Id,
        [string]$Team = ''
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
        Team        = $(if ([string]::IsNullOrWhiteSpace($Team)) {
            Get-ScriptHubTeamForEntry -Name $N -Category $Cat -ScriptText $Scr
        } else { $Team })
    }
}

# === Load the catalog into memory (in-memory only) ===
function Initialize-ScriptHub {
    $global:Commands.Clear()
    foreach ($cmd in (Get-ScriptHubCatalog)) { [void]$global:Commands.Add($cmd) }
    [void](Test-ScriptHubCatalog)
    return $global:Commands.Count
}

function Test-ScriptHubCatalog {
    $invalid = @($global:Commands | Where-Object {
        [string]::IsNullOrWhiteSpace($_.Id) -or
        [string]::IsNullOrWhiteSpace($_.Name) -or
        [string]::IsNullOrWhiteSpace($_.Category) -or
        [string]::IsNullOrWhiteSpace($_.Script)
    })
    if ($invalid.Count -gt 0) {
        throw "Catalog contains $($invalid.Count) incomplete command(s)."
    }

    $duplicateIds = @($global:Commands | Group-Object -Property Id | Where-Object Count -gt 1)
    if ($duplicateIds.Count -gt 0) {
        $ids = ($duplicateIds | ForEach-Object Name) -join ', '
        throw "Catalog contains duplicate command IDs: $ids"
    }

    $duplicateNames = @($global:Commands | Group-Object -Property Name | Where-Object Count -gt 1)
    if ($duplicateNames.Count -gt 0) {
        $names = ($duplicateNames | ForEach-Object Name) -join ', '
        throw "Catalog contains duplicate command names: $names"
    }

    return $global:Commands.Count
}

# === Filtering / search ===
function Select-ScriptHubCommand {
    param(
        [string]$SearchText = '',
        [string]$Category   = 'All',
        [string]$PSVersion  = 'All',
        [string]$Team       = 'All'
    )
    $res = $global:Commands
    if ($Category  -ne 'All') { $res = $res | Where-Object { $_.Category -eq $Category } }
    if ($PSVersion -ne 'All') { $res = $res | Where-Object { $_.PSVersion -like "*$PSVersion*" } }
    if ($Team      -ne 'All') { $res = $res | Where-Object { $_.Team -eq $Team } }
    if ($SearchText.Trim() -ne '') {
        $s = $SearchText.ToLower()
        $res = $res | Where-Object {
            "$($_.Name) $($_.Description) $($_.Script) $($_.Tags) $($_.Category) $($_.SubCategory) $($_.Notes) $($_.Team)".ToLower().Contains($s)
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

function Get-ScriptHubTeam {
    return @('All') + @($global:Commands | ForEach-Object { $_.Team } | Sort-Object -Unique)
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
            $out = [regex]::Replace($out, $token, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $val })
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
    param(
        [string]$ScriptText,
        [string]$CmdName,
        [string]$PSVersion = '5 & 7'
    )
    $dir = $global:ScriptHubConfig.TempFolder
    if (-not (Test-Path $dir)) { [void](New-Item -Path $dir -ItemType Directory -Force) }
    $safeName = $CmdName -replace '[^\w\-]', '_'
    $stamp    = Get-Date -Format 'yyyyMMdd_HHmmss'
    $file     = Join-Path $dir ($safeName + '_' + $stamp + '.ps1')
    $ScriptText | Set-Content -Path $file -Encoding UTF8
    $requiresPowerShell7 = $PSVersion -match '(?i)^\s*7(?:\s*\(recommended\))?\s*$'
    if ($requiresPowerShell7) {
        $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
        if (-not $pwsh) { throw 'This script requires PowerShell 7, but pwsh.exe was not found.' }
        $shell = $pwsh.Source
    } else {
        $shell = (Get-Command powershell.exe -ErrorAction Stop).Source
    }
    Start-Process -FilePath $shell -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', $file)
    return $file
}

function Install-ScriptHubDependencies {
    param(
        [psobject]$Dependencies,
        [string]$CommandName = 'ScriptHub dependencies'
    )
    if (-not $Dependencies.Modules -or @($Dependencies.Modules).Count -eq 0) { return $null }

    $lines = @(
        '$ErrorActionPreference = ''Stop'''
        'Write-Host "Installing ScriptHub dependencies..." -ForegroundColor Cyan'
    )
    foreach ($module in $Dependencies.Modules) {
        $safeModule = $module -replace "'", "''"
        $lines += "Install-Module -Name '$safeModule' -Scope CurrentUser -Force -AllowClobber"
    }
    $lines += 'Write-Host "All dependencies are installed." -ForegroundColor Green'
    $lines += 'Read-Host "Press Enter to close"'

    $shell = $null
    if ($Dependencies.RequiresPowerShell7) {
        $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
        if (-not $pwsh) { throw 'This script requires PowerShell 7. Install PowerShell 7 first.' }
        $shell = $pwsh.Source
    } else {
        $shell = (Get-Command powershell.exe -ErrorAction Stop).Source
    }

    $dir = $global:ScriptHubConfig.TempFolder
    if (-not (Test-Path $dir)) { [void](New-Item -Path $dir -ItemType Directory -Force) }
    $safeName = $CommandName -replace '[^\w\-]', '_'
    $file = Join-Path $dir ($safeName + '_dependencies.ps1')
    $lines -join [Environment]::NewLine | Set-Content -Path $file -Encoding UTF8
    Start-Process -FilePath $shell -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', $file)
    return $file
}

function Open-ScriptHubUrl {
    param([string]$Url, [string]$Label = 'URL')
    if ([string]::IsNullOrWhiteSpace($Url) -or $Url -match '<[^>]+>') {
        throw "$Label is not configured. Replace the placeholder URL in ScriptHub.Core.ps1."
    }
    $uri = $null
    if (-not [System.Uri]::TryCreate($Url, [System.UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -notin @('http','https')) {
        throw "$Label is not a valid HTTP or HTTPS URL."
    }
    Start-Process -FilePath $Url
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
        [string]$Notes,
        [string]$Team = ''
    )
    $bt = '`'          # backtick used as PowerShell line continuation
    $teamValue = if ([string]::IsNullOrWhiteSpace($Team)) {
        Get-ScriptHubTeamForEntry -Name $Name -Category $Category -ScriptText $ScriptText
    } else { $Team }
    $quote = {
        param([string]$Value)
        return "'$(($Value -replace "'", "''") -replace '`', '``')'"
    }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('    $d += New-CmdEntry -N ' + (&$quote $Name) + ' -Cat ' + (&$quote $Category) + ' -Sub ' + (&$quote $SubCategory) + ' ' + $bt)
    [void]$sb.AppendLine('        -Desc ' + (&$quote $Description) + ' ' + $bt)
    [void]$sb.AppendLine('        -PSV ' + (&$quote $PSVersion) + ' -Tags ' + (&$quote $Tags) + ' ' + $bt)
    [void]$sb.AppendLine('        -Notes ' + (&$quote $Notes) + ' -Team ' + (&$quote $teamValue) + ' ' + $bt)
    [void]$sb.AppendLine("        -Scr @'")
    [void]$sb.AppendLine($ScriptText.TrimEnd())
    [void]$sb.AppendLine("'@")
    return $sb.ToString()
}

# === Open the intake / feedback pages published on the ScriptHub site ===
function Open-ScriptHubRequestForm  { Open-ScriptHubUrl -Url $global:ScriptHubConfig.RequestFormUrl -Label 'Request form URL' }
function Open-ScriptHubFeedbackForm { Open-ScriptHubUrl -Url $global:ScriptHubConfig.FeedbackFormUrl -Label 'Feedback URL' }
