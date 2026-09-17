# SP Engineer Toolkit v2.0 - Script Repository
# CSV Persistence | .ps1 Export | Run with Parameter UI
# Author: Ismael Najera

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === GLOBAL CONFIG ===
$global:DataFile   = Join-Path $env:APPDATA "SPToolkit\commands.csv"
$global:JsonLegacy = Join-Path $env:APPDATA "SPToolkit\commands.json"
$global:Commands   = [System.Collections.ArrayList]::new()

# === WIN95 STYLE CONSTANTS ===
$script:C_Gray     = [System.Drawing.Color]::FromArgb(192,192,192)
$script:C_DarkGray = [System.Drawing.Color]::FromArgb(128,128,128)
$script:C_White    = [System.Drawing.Color]::White
$script:C_Navy     = [System.Drawing.Color]::FromArgb(0,0,128)
$script:C_TermBG   = [System.Drawing.Color]::FromArgb(1,1,30)
$script:C_TermFG   = [System.Drawing.Color]::FromArgb(0,255,0)
$script:C_DarkRed  = [System.Drawing.Color]::FromArgb(139,0,0)
$script:FNormal    = New-Object System.Drawing.Font("Microsoft Sans Serif",8.25)
$script:FBold      = New-Object System.Drawing.Font("Microsoft Sans Serif",8.25,[System.Drawing.FontStyle]::Bold)
$script:FMono      = New-Object System.Drawing.Font("Consolas",9)
$script:FTitle     = New-Object System.Drawing.Font("Microsoft Sans Serif",10,[System.Drawing.FontStyle]::Bold)

# === HELPER: Command entry object ===
function New-CmdEntry {
    param([string]$N,[string]$Cat,[string]$Sub,[string]$Desc,[string]$Scr,[string]$PSV,[string]$Tags,[string]$Notes,[string]$Id)
    [PSCustomObject]@{
        Id = $(if($Id){$Id}else{[guid]::NewGuid().ToString("N").Substring(0,8)})
        Name=$N; Category=$Cat; SubCategory=$Sub; Description=$Desc
        Script=$Scr; PSVersion=$PSV; Tags=$Tags; Notes=$Notes
    }
}

# === HELPER: Win95 button ===
function New-W95Btn {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=90,[int]$H=25)
    $b = New-Object System.Windows.Forms.Button
    $b.Text=$Text; $b.Location=New-Object System.Drawing.Point($X,$Y)
    $b.Size=New-Object System.Drawing.Size($W,$H); $b.Font=$script:FNormal
    $b.FlatStyle=[System.Windows.Forms.FlatStyle]::Standard
    $b.BackColor=$script:C_Gray; $b.UseVisualStyleBackColor=$false
    return $b
}

# === HELPER: Win95 label ===
function New-W95Lbl {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=200,[int]$H=16,[switch]$Bold)
    $l = New-Object System.Windows.Forms.Label
    $l.Text=$Text; $l.Location=New-Object System.Drawing.Point($X,$Y)
    $l.Size=New-Object System.Drawing.Size($W,$H)
    $l.Font=$(if($Bold){$script:FBold}else{$script:FNormal})
    $l.BackColor=$script:C_Gray
    return $l
}

# ================================================================
# DEFAULT COMMANDS DATABASE
# ================================================================
function Get-DefaultCommands {
    $d = @()

    # --- MODULES ---
    $d += New-CmdEntry -N "SharePoint Online Management Shell" -Cat "Modules" -Sub "Installation" `
        -Desc "Official Microsoft module for SharePoint Online administration." `
        -Scr ("# Install the module`n" +
              "Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force`n`n" +
              "# Verify installation`n" +
              "Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable`n`n" +
              "# Import module`n" +
              "Import-Module Microsoft.Online.SharePoint.PowerShell") `
        -PSV "5 & 7" -Tags "module, SPO, install, admin" `
        -Notes "Requires SharePoint Admin permissions. On PS7, some legacy cmdlets may need -UseWindowsPowerShell."

    $d += New-CmdEntry -N "PnP PowerShell" -Cat "Modules" -Sub "Installation" `
        -Desc "Community-driven PnP module with 600+ cmdlets for SharePoint Online." `
        -Scr ("# Install PnP PowerShell (PS7 recommended)`n" +
              "Install-Module -Name PnP.PowerShell -Force`n`n" +
              "# For PS5 (legacy version)`n" +
              "Install-Module -Name SharePointPnPPowerShellOnline -Force`n`n" +
              "# Verify installed version`n" +
              "Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version") `
        -PSV "7 (recommended)" -Tags "module, PnP, install, community" `
        -Notes "PnP.PowerShell targets PS7+. SharePointPnPPowerShellOnline is the legacy PS5 version."

    $d += New-CmdEntry -N "Microsoft Graph PowerShell SDK" -Cat "Modules" -Sub "Installation" `
        -Desc "SDK to interact with Microsoft Graph API. Manages users, groups, OneDrive, Entra ID." `
        -Scr ("# Install Graph modules`n" +
              "Install-Module Microsoft.Graph -Force`n`n" +
              "# Or install only specific sub-modules`n" +
              "Install-Module Microsoft.Graph.Sites -Force`n" +
              "Install-Module Microsoft.Graph.Users -Force`n" +
              "Install-Module Microsoft.Graph.Groups -Force`n`n" +
              "# Verify`n" +
              "Get-Module Microsoft.Graph* -ListAvailable | Select Name, Version") `
        -PSV "5 & 7" -Tags "module, graph, API, entra, install" `
        -Notes "Install only the sub-modules you need to reduce load time."

    $d += New-CmdEntry -N "Exchange Online Management" -Cat "Modules" -Sub "Installation" `
        -Desc "Module to manage Exchange Online. Useful when SPO issues involve mailboxes or M365 groups." `
        -Scr ("# Install`n" +
              "Install-Module -Name ExchangeOnlineManagement -Force`n`n" +
              "# Connect`n" +
              "Connect-ExchangeOnline -UserPrincipalName admin@tenant.onmicrosoft.com`n`n" +
              "# Check M365 groups (which create SPO team sites)`n" +
              "Get-UnifiedGroup -Identity 'GroupName' | FL") `
        -PSV "5 & 7" -Tags "module, exchange, groups, M365" `
        -Notes "M365 groups are linked to SPO team sites."

    # --- PnP REGISTRATION ---
    $d += New-CmdEntry -N "Register PnP Entra ID App (Interactive)" -Cat "PnP Registration" -Sub "App Registration" `
        -Desc "Registers an Entra ID app for PnP PowerShell with interactive login." `
        -Scr ("# Register app for PnP with interactive login`n" +
              "# IMPORTANT: Requires Global Admin or Application Admin permissions`n`n" +
              "Register-PnPEntraIDAppForInteractiveLogin ```n" +
              "    -ApplicationName 'PnP-PowerShell-App' ```n" +
              "    -Tenant '<TenantName>.onmicrosoft.com' ```n" +
              "    -Interactive`n`n" +
              "# The command will open the browser for authentication`n" +
              "# Upon completion, it will display the Application (Client) ID`n" +
              "# SAVE this ID - it is needed for Connect-PnPOnline") `
        -PSV "7" -Tags "PnP, registration, app, entra, client ID, application ID" `
        -Notes "The generated Application ID is used in: Connect-PnPOnline -Url <url> -Interactive -ClientId <AppId>"

    $d += New-CmdEntry -N "Register PnP Azure AD App (Certificate)" -Cat "PnP Registration" -Sub "App Registration" `
        -Desc "Registers an Entra ID app with certificate authentication. Ideal for automated scripts." `
        -Scr ("# Register app with auto-generated certificate`n" +
              "Register-PnPAzureADApp ```n" +
              "    -ApplicationName 'PnP-Automation' ```n" +
              "    -Tenant '<TenantName>.onmicrosoft.com' ```n" +
              "    -Store CurrentUser ```n" +
              "    -SharePointApplicationPermissions 'Sites.FullControl.All' ```n" +
              "    -GraphApplicationPermissions 'Group.ReadWrite.All' ```n" +
              "    -Interactive`n`n" +
              "# Connect using certificate`n" +
              "Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com' ```n" +
              "    -ClientId '<AppId>' ```n" +
              "    -Tenant '<TenantName>.onmicrosoft.com' ```n" +
              "    -Thumbprint '<CertThumbprint>'") `
        -PSV "7" -Tags "PnP, registration, certificate, app, automation" `
        -Notes "Use -Store CurrentUser to save the cert in the user certificate store."

    $d += New-CmdEntry -N "Get registered PnP App ID" -Cat "PnP Registration" -Sub "Verification" `
        -Desc "Verify and retrieve the Application ID of PnP apps already registered in Entra ID." `
        -Scr ("# Option 1: Search app by name in Entra ID via Graph`n" +
              "Connect-MgGraph -Scopes 'Application.Read.All'`n`n" +
              "Get-MgApplication -Filter `"displayName eq 'PnP-PowerShell-App'`" |`n" +
              "    Select-Object DisplayName, AppId, Id`n`n" +
              "# Option 2: List all apps with 'PnP' in the name`n" +
              "Get-MgApplication -Filter `"startswith(displayName,'PnP')`" |`n" +
              "    Select-Object DisplayName, AppId`n`n" +
              "# Option 3: From Azure Portal`n" +
              "# Entra ID > App registrations > Search by name > Application (client) ID") `
        -PSV "7" -Tags "PnP, app ID, verify, entra, graph" `
        -Notes "AppId = Application (Client) ID. Id = Object ID. For PnP, use the AppId."

    # --- CONNECTION ---
    $d += New-CmdEntry -N "Connect-SPOService" -Cat "Connection" -Sub "SPO Admin" `
        -Desc "Connects to the SharePoint Online admin center using the SPO module." `
        -Scr ("# Standard connection (opens login prompt)`n" +
              "Connect-SPOService -Url 'https://<TenantName>-admin.sharepoint.com'`n`n" +
              "# Verify connection`n" +
              "Get-SPOTenant | Select-Object StorageQuota, SharingCapability") `
        -PSV "5 & 7" -Tags "connection, SPO, admin, tenant" `
        -Notes "URL must be the admin center: https://<tenant>-admin.sharepoint.com"

    $d += New-CmdEntry -N "Connect-PnPOnline (Methods)" -Cat "Connection" -Sub "PnP" `
        -Desc "Different connection methods with PnP PowerShell." `
        -Scr ("# Method 1: Interactive with registered app (RECOMMENDED)`n" +
              "Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -Interactive ```n" +
              "    -ClientId '<AppId>'`n`n" +
              "# Method 2: With credentials (legacy)`n" +
              "`$cred = Get-Credential`n" +
              "Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -Credentials `$cred`n`n" +
              "# Method 3: With certificate (automation)`n" +
              "Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com' ```n" +
              "    -ClientId '<AppId>' -Tenant '<TenantName>.onmicrosoft.com' ```n" +
              "    -Thumbprint '<CertThumbprint>'`n`n" +
              "# Verify connection`n" +
              "Get-PnPContext | Select Url") `
        -PSV "7" -Tags "connection, PnP, interactive, certificate, credentials" `
        -Notes "For Interactive, you need the ClientId from your registered app."

    # --- SITE MANAGEMENT ---
    $d += New-CmdEntry -N "Get-SPOSite (Site info)" -Cat "Site Management" -Sub "Query" `
        -Desc "Retrieve SharePoint Online site information." `
        -Scr ("# Get all sites`n" +
              "Get-SPOSite -Limit All | Select Url, Template, StorageUsageCurrent, SharingCapability`n`n" +
              "# Specific site with detail`n" +
              "Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Detailed | FL`n`n" +
              "# Filter by template`n" +
              "Get-SPOSite -Limit All -Template 'GROUP#0' | Select Url, GroupId`n`n" +
              "# Sites with external sharing enabled`n" +
              "Get-SPOSite -Limit All | Where-Object { `$_.SharingCapability -ne 'Disabled' } |`n" +
              "    Select Url, SharingCapability") `
        -PSV "5 & 7" -Tags "site, SPO, info, sharing, template, quota" `
        -Notes "GROUP#0 = M365 team sites. STS#3 = communication sites. -Detailed for all properties."

    $d += New-CmdEntry -N "Set-SPOSite (Modify site)" -Cat "Site Management" -Sub "Configuration" `
        -Desc "Modify site configuration: sharing, storage quota, lock status." `
        -Scr ("# Change sharing capability`n" +
              "Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -SharingCapability ExternalUserAndGuestSharing`n`n" +
              "# SharingCapability values:`n" +
              "# Disabled - No external sharing`n" +
              "# ExistingExternalUserSharingOnly - Existing guests only`n" +
              "# ExternalUserSharingOnly - New and existing guests`n" +
              "# ExternalUserAndGuestSharing - Anyone (anonymous links)`n`n" +
              "# Change storage quota`n" +
              "Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -StorageQuota 5120 -StorageQuotaWarningLevel 4096`n`n" +
              "# Lock/Unlock site`n" +
              "Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -LockState NoAccess  # ReadOnly | Unlock | NoAccess") `
        -PSV "5 & 7" -Tags "site, sharing, quota, lock, configuration" `
        -Notes "Site SharingCapability cannot exceed the tenant level setting."

    # --- PERMISSIONS ---
    $d += New-CmdEntry -N "Site Collection Admin (Add/Remove)" -Cat "Permissions" -Sub "Admin" `
        -Desc "Add or remove site collection administrators." `
        -Scr ("# Add Site Collection Admin via SPO`n" +
              "Set-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -LoginName '<UserEmail>' ```n" +
              "    -IsSiteCollectionAdmin `$true`n`n" +
              "# Remove Site Collection Admin`n" +
              "Set-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -LoginName '<UserEmail>' ```n" +
              "    -IsSiteCollectionAdmin `$false`n`n" +
              "# Via PnP - List current admins`n" +
              "Get-PnPSiteCollectionAdmin`n`n" +
              "# Via PnP - Add admin`n" +
              "Add-PnPSiteCollectionAdmin -Owners '<UserEmail>'") `
        -PSV "5 & 7" -Tags "permissions, admin, site collection, access" `
        -Notes "Being Site Collection Admin grants full control over the site."

    $d += New-CmdEntry -N "Verify user permissions" -Cat "Permissions" -Sub "Query" `
        -Desc "Check what permissions a user has on a site or list." `
        -Scr ("# Get user info on a site`n" +
              "Get-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -LoginName '<UserEmail>'`n`n" +
              "# List all users on a site`n" +
              "Get-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Limit All`n`n" +
              "# PnP - Check permissions on a site`n" +
              "Get-PnPWeb -Includes RoleAssignments`n`n" +
              "# PnP - Permissions on a list/library`n" +
              "Get-PnPList -Identity 'Documents' -Includes RoleAssignments, HasUniqueRoleAssignments") `
        -PSV "5 & 7" -Tags "permissions, user, verify, roles, access" `
        -Notes "HasUniqueRoleAssignments = true means broken inheritance (unique permissions)."

    $d += New-CmdEntry -N "User Information List - Cleanup" -Cat "Permissions" -Sub "Troubleshooting" `
        -Desc "Completely remove a user from the User Information List and re-add them." `
        -Scr ("# Step 1: Get the user ID in the UIL`n" +
              "`$user = Get-PnPUser | Where-Object { `$_.Email -eq '<UserEmail>' }`n" +
              "`$user | Select Id, Title, Email, LoginName`n`n" +
              "# Step 2: Remove user from the UIL`n" +
              "Remove-PnPUser -Identity `$user.Id -Force`n`n" +
              "# Step 3: Re-add (auto re-added on next access)`n" +
              "# Or force:`n" +
              "New-PnPUser -LoginName '<UserEmail>'`n`n" +
              "# Step 4: Verify`n" +
              "Get-PnPUser | Where-Object { `$_.Email -eq '<UserEmail>' }") `
        -PSV "7" -Tags "UIL, user, cleanup, re-add, permissions, troubleshooting" `
        -Notes "WARNING: This removes the user from ALL site groups. Reassign permissions afterwards."

    # --- RECYCLE BIN ---
    $d += New-CmdEntry -N "Recycle Bin - Restore items" -Cat "Recycle Bin" -Sub "Restore" `
        -Desc "Search and restore items from first and second stage recycle bin." `
        -Scr ("# List items in recycle bin (first stage)`n" +
              "Get-PnPRecycleBinItem | Select Title, ItemType, DeletedByEmail, DeletedDate, ItemState | FT`n`n" +
              "# Search for a specific file`n" +
              "Get-PnPRecycleBinItem | Where-Object { `$_.Title -like '*<SearchTerm>*' }`n`n" +
              "# Restore specific item by ID`n" +
              "Restore-PnPRecycleBinItem -Identity '<ItemGuid>' -Force`n`n" +
              "# Restore ALL items (USE WITH CAUTION)`n" +
              "Get-PnPRecycleBinItem | Restore-PnPRecycleBinItem -Force`n`n" +
              "# Second stage recycle bin (admin)`n" +
              "Get-PnPRecycleBinItem -SecondStage`n" +
              "Get-PnPRecycleBinItem -SecondStage |`n" +
              "    Where-Object { `$_.Title -like '*<SearchTerm>*' } |`n" +
              "    Restore-PnPRecycleBinItem -Force") `
        -PSV "7" -Tags "recycle bin, restore, delete, recover" `
        -Notes "Second stage items = deleted from first stage. Max retention: 93 days total."

    # --- FILES ---
    $d += New-CmdEntry -N "Move/Copy files (PnP)" -Cat "Files" -Sub "Operations" `
        -Desc "Move and copy files/folders between libraries or sites using PnP." `
        -Scr ("# Copy file`n" +
              "Copy-PnPFile ```n" +
              "    -SourceUrl '/sites/<SourceSite>/Shared Documents/file.docx' ```n" +
              "    -TargetUrl '/sites/<TargetSite>/Shared Documents/file.docx' ```n" +
              "    -Force`n`n" +
              "# Move file`n" +
              "Move-PnPFile ```n" +
              "    -SourceUrl '/sites/<SiteName>/Shared Documents/file.docx' ```n" +
              "    -TargetUrl '/sites/<SiteName>/Documents/Archive/file.docx' ```n" +
              "    -Force`n`n" +
              "# Move entire folder`n" +
              "Move-PnPFolder ```n" +
              "    -Folder 'Shared Documents/OldFolder' ```n" +
              "    -TargetFolder 'Shared Documents/Archive'") `
        -PSV "7" -Tags "files, move, copy, folder, library" `
        -Notes "URLs are server-relative. For cross-site, both sites must be in the same tenant."

    $d += New-CmdEntry -N "Version History - Configure" -Cat "Files" -Sub "Versioning" `
        -Desc "Configure and verify version history on document libraries." `
        -Scr ("# Check version settings`n" +
              "Get-PnPList -Identity 'Documents' |`n" +
              "    Select Title, EnableVersioning, MajorVersionLimit, EnableMinorVersions`n`n" +
              "# Enable versioning`n" +
              "Set-PnPList -Identity 'Documents' ```n" +
              "    -EnableVersioning `$true ```n" +
              "    -MajorVersions 500`n`n" +
              "# Enable minor versions`n" +
              "Set-PnPList -Identity 'Documents' ```n" +
              "    -EnableMinorVersions `$true ```n" +
              "    -MajorVersions 500 ```n" +
              "    -MinorVersions 10`n`n" +
              "# View file versions`n" +
              "Get-PnPFileVersion -Url '/sites/<SiteName>/Shared Documents/file.docx'") `
        -PSV "7" -Tags "versions, history, library, versioning" `
        -Notes "Default limit: 500 major versions."

    # --- ONEDRIVE ---
    $d += New-CmdEntry -N "OneDrive Admin Access" -Cat "OneDrive" -Sub "Admin" `
        -Desc "Grant administrative access to a user's OneDrive." `
        -Scr ("# Grant admin access to a user's OneDrive`n" +
              "Set-SPOUser ```n" +
              "    -Site 'https://<TenantName>-my.sharepoint.com/personal/<User_Domain_Com>' ```n" +
              "    -LoginName '<AdminEmail>' ```n" +
              "    -IsSiteCollectionAdmin `$true`n`n" +
              "# Provision OneDrive for a user`n" +
              "Request-SPOPersonalSite -UserEmails @('<UserEmail>')`n`n" +
              "# Get OneDrive URL (via Graph)`n" +
              "Connect-MgGraph -Scopes 'User.Read.All'`n" +
              "`$u = Get-MgUser -UserId '<UserEmail>' -Property MySite`n" +
              "`$u.MySite") `
        -PSV "5 & 7" -Tags "onedrive, admin, access, provision, personal site" `
        -Notes "OneDrive URL format: https://<tenant>-my.sharepoint.com/personal/<user_domain_com>"

    # --- TENANT ---
    $d += New-CmdEntry -N "Get-SPOTenant (Tenant Config)" -Cat "Tenant" -Sub "Configuration" `
        -Desc "Retrieve the global SharePoint Online tenant configuration." `
        -Scr ("# Get full tenant configuration`n" +
              "Get-SPOTenant | FL`n`n" +
              "# Key properties for troubleshooting`n" +
              "Get-SPOTenant | Select-Object ```n" +
              "    SharingCapability, ```n" +
              "    DefaultSharingLinkType, ```n" +
              "    FileAnonymousLinkType, ```n" +
              "    FolderAnonymousLinkType, ```n" +
              "    RequireAcceptingAccountMatchInvitedAccount, ```n" +
              "    ExternalUserExpirationRequired, ```n" +
              "    ExternalUserExpireInDays, ```n" +
              "    OneDriveSharingCapability, ```n" +
              "    EnableGuestSignInAcceleration") `
        -PSV "5 & 7" -Tags "tenant, configuration, sharing, global" `
        -Notes "Tenant config is the ceiling for each site's configuration."

    # --- TROUBLESHOOTING ---
    $d += New-CmdEntry -N "Site Health Check" -Cat "Troubleshooting" -Sub "Diagnostics" `
        -Desc "Commands to verify the status and health of a SharePoint site." `
        -Scr ("# Check if site exists and its status`n" +
              "Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' |`n" +
              "    Select Url, Status, LockState, DenyAddAndCustomizePages`n`n" +
              "# Check if site is in ReadOnly mode`n" +
              "`$site = Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Detailed`n" +
              "`$site.LockState  # Unlock | ReadOnly | NoAccess`n`n" +
              "# PnP connection test`n" +
              "Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Interactive -ClientId '<AppId>'`n" +
              "Get-PnPWeb | Select Title, Url, LastItemModifiedDate") `
        -PSV "5 & 7" -Tags "status, diagnostics, health, lock, troubleshooting" `
        -Notes "LockState: Unlock=normal, ReadOnly=read-only, NoAccess=blocked."

    $d += New-CmdEntry -N "PITR - Point In Time Restore" -Cat "Troubleshooting" -Sub "Restore" `
        -Desc "Info and commands related to Point In Time Restore for SPO sites." `
        -Scr ("# PITR is requested to the backend team via ICM/escalation`n`n" +
              "# Self-service restore (limited):`n" +
              "# Admin Center > Active Sites > Select site > Restore`n`n" +
              "# Required information to request PITR from backend:`n" +
              "# 1. Site URL`n" +
              "# 2. Exact restore date/time (UTC)`n" +
              "# 3. Business justification`n" +
              "# 4. Tenant ID`n" +
              "# 5. Tenant admin confirmation") `
        -PSV "5 & 7" -Tags "PITR, restore, backup, point in time, backend" `
        -Notes "PITR has a maximum of 14 days. Requested via escalation to the backend team."

    $d += New-CmdEntry -N "HAR File - Capture instructions" -Cat "Troubleshooting" -Sub "Diagnostics" `
        -Desc "Instructions to request HAR file capture from the customer." `
        -Scr ("# === INSTRUCTIONS FOR THE CUSTOMER ===`n" +
              "# 1. Open the browser (Edge/Chrome)`n" +
              "# 2. Press F12 to open DevTools`n" +
              "# 3. Go to the 'Network' tab`n" +
              "# 4. Check the 'Preserve log' checkbox`n" +
              "# 5. Reproduce the issue`n" +
              "# 6. Right-click on the request list`n" +
              "# 7. Select 'Save all as HAR with content'`n" +
              "# 8. Send the .har file`n`n" +
              "# === TO ANALYZE ===`n" +
              "# - Open at https://toolbox.googleapps.com/apps/har_analyzer/`n" +
              "# - Or in DevTools > Network > Import HAR`n" +
              "# - Look for requests with status 400, 403, 404, 500`n" +
              "# - Check authentication headers`n" +
              "# - Verify response times") `
        -PSV "N/A" -Tags "HAR, network, troubleshooting, browser, diagnostics" `
        -Notes "HAR files may contain tokens. Ask customer NOT to clear sensitive data before sending."

    # --- SHARING ---
    $d += New-CmdEntry -N "External Sharing - Verify and configure" -Cat "Sharing" -Sub "External" `
        -Desc "Verify and modify external sharing configuration at tenant and site level." `
        -Scr ("# Tenant level`n" +
              "Get-SPOTenant | Select SharingCapability, OneDriveSharingCapability`n`n" +
              "# Site level`n" +
              "Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' |`n" +
              "    Select Url, SharingCapability`n`n" +
              "# Change site sharing`n" +
              "Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' ```n" +
              "    -SharingCapability ExternalUserSharingOnly`n`n" +
              "# Check existing guests`n" +
              "Get-SPOExternalUser -SiteUrl 'https://<TenantName>.sharepoint.com/sites/<SiteName>' |`n" +
              "    Select DisplayName, AcceptedAs, InvitedAs, WhenCreated`n`n" +
              "# Remove external guest`n" +
              "Remove-SPOExternalUser -UniqueIDs @('<ExternalUserID>')") `
        -PSV "5 & 7" -Tags "sharing, external, guest, invitation, B2B" `
        -Notes "Hierarchy: Disabled < ExistingExternalUserSharingOnly < ExternalUserSharingOnly < ExternalUserAndGuestSharing"

    return $d
}

# ================================================================
# SAVE / LOAD DATABASE (CSV)
# ================================================================
function Save-Database {
    $dir = Split-Path $global:DataFile -Parent
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    if ($global:Commands.Count -gt 0) {
        $global:Commands.ToArray() | Export-Csv -Path $global:DataFile -NoTypeInformation -Encoding UTF8
    }
}

function Load-Database {
    $global:Commands.Clear()

    # Try loading CSV
    if (Test-Path $global:DataFile) {
        try {
            $data = Import-Csv -Path $global:DataFile -Encoding UTF8
            foreach ($item in $data) { $global:Commands.Add($item) | Out-Null }
        } catch { }
    }

    # Migration: if CSV empty but old JSON exists, import from JSON
    if ($global:Commands.Count -eq 0 -and (Test-Path $global:JsonLegacy)) {
        try {
            $data = Get-Content -Path $global:JsonLegacy -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($item in $data) { $global:Commands.Add($item) | Out-Null }
            Save-Database   # persist as CSV
        } catch { }
    }

    # Default commands if still empty
    if ($global:Commands.Count -eq 0) {
        foreach ($cmd in (Get-DefaultCommands)) { $global:Commands.Add($cmd) | Out-Null }
        Save-Database
    }
}

# ================================================================
# SHOW-RUNFORM: Parameter detection + execution UI
# ================================================================
function Show-RunForm {
    param([string]$ScriptText, [string]$CmdName)

    # --- Detect <Placeholder> patterns ---
    $phList = [System.Collections.Generic.List[string]]::new()
    $htmlTags = @('br','p','div','span','a','b','i','strong','em','ul','li','ol','h1','h2','h3','table','tr','td','th','hr','img')

    # Pattern: <...> literal angle brackets
    $m = :Matches($ScriptText, '<([A-Za-z][A-Za-z0-9_\- ]{1,40})>')
    foreach ($match in $m) {
        $ph = $match.Groups[1].Value.Trim()
        if ($ph.ToLower() -notin $htmlTags -and $ph -notin $phList) {
            $phList.Add($ph)
        }
    }

    $hasParams = $phList.Count -gt 0
    $paramHeight = if ($hasParams) { :Min(($phList.Count * 30 + 60), 300) } else { 0 }
    $formH = 550 + $paramHeight

    # --- Build Form ---
    $rf = New-Object System.Windows.Forms.Form
    $rf.Text = "Run: $CmdName"
    $rf.Size = New-Object System.Drawing.Size(880, $formH)
    $rf.StartPosition = "CenterParent"
    $rf.BackColor = $script:C_Gray
    $rf.Font = $script:FNormal
    $rf.MinimumSize = New-Object System.Drawing.Size(700, 450)

    $y = 8
    $inputFields = @{}

    # --- Parameters Section ---
    if ($hasParams) {
        $grpParams = New-Object System.Windows.Forms.GroupBox
        $grpParams.Text = " Parameters detected - fill in values "
        $grpParams.Font = $script:FBold
        $grpParams.Location = New-Object System.Drawing.Point(8, $y)
        $grpParams.Size = New-Object System.Drawing.Size(848, ($paramHeight - 10))
        $grpParams.BackColor = $script:C_Gray
        $rf.Controls.Add($grpParams)

        $py = 20
        foreach ($ph in $phList) {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = "${ph}:"
            $lbl.Location = New-Object System.Drawing.Point(12, ($py + 3))
            $lbl.Size = New-Object System.Drawing.Size(180, 18)
            $lbl.Font = $script:FNormal
            $grpParams.Controls.Add($lbl)

            $txt = New-Object System.Windows.Forms.TextBox
            $txt.Location = New-Object System.Drawing.Point(198, $py)
            $txt.Size = New-Object System.Drawing.Size(630, 22)
            $txt.Font = $script:FNormal
            $grpParams.Controls.Add($txt)
            $inputFields[$ph] = $txt
            $py += 28
        }

        $y += $paramHeight - 5
    }

    # --- Button Bar ---
    $pnlBtns = New-Object System.Windows.Forms.Panel
    $pnlBtns.Location = New-Object System.Drawing.Point(8, $y)
    $pnlBtns.Size = New-Object System.Drawing.Size(848, 34)
    $pnlBtns.BackColor = $script:C_Gray
    $rf.Controls.Add($pnlBtns)

    $bx = 0
    if ($hasParams) {
        $btnApply = New-W95Btn -Text "Apply Parameters" -X $bx -Y 2 -W 130 -H 28
        $btnApply.Font = $script:FBold
        $pnlBtns.Controls.Add($btnApply)
        $bx += 140
    }

    $btnRunPS = New-W95Btn -Text ([char]9654 + " Open in PowerShell") -X $bx -Y 2 -W 170 -H 28
    $btnRunPS.Font = $script:FBold
    $pnlBtns.Controls.Add($btnRunPS)
    $bx += 180

    $btnCopyR = New-W95Btn -Text "Copy to Clipboard" -X $bx -Y 2 -W 140 -H 28
    $pnlBtns.Controls.Add($btnCopyR)

    $btnCloseR = New-W95Btn -Text "Close" -X 758 -Y 2 -W 90 -H 28
    $pnlBtns.Controls.Add($btnCloseR)

    $y += 38

    # --- Script Preview Label ---
    $lblPrev = New-W95Lbl -Text "Script Preview (editable before running):" -X 8 -Y $y -W 400 -Bold
    $rf.Controls.Add($lblPrev)
    $y += 18

    # --- Script Preview RichTextBox ---
    $txtPrev = New-Object System.Windows.Forms.RichTextBox
    $txtPrev.Location = New-Object System.Drawing.Point(8, $y)
    $txtPrev.Font = $script:FMono
    $txtPrev.BackColor = $script:C_TermBG
    $txtPrev.ForeColor = $script:C_TermFG
    $txtPrev.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $txtPrev.WordWrap = $false
    $txtPrev.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Both
    $txtPrev.Text = $ScriptText
    $txtPrev.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
                      [System.Windows.Forms.AnchorStyles]::Bottom -bor
                      [System.Windows.Forms.AnchorStyles]::Left -bor
                      [System.Windows.Forms.AnchorStyles]::Right
    $txtPrev.Size = New-Object System.Drawing.Size(848, ($formH - $y - 80))
    $rf.Controls.Add($txtPrev)

    # --- Events ---
    if ($hasParams) {
        $btnApply.Add_Click({
            $script:tmpScript = $ScriptText
            foreach ($ph in $phList) {
                $val = $inputFields[$ph].Text
                if ($val -ne "") {
                    $script:tmpScript = $script:tmpScript -replace [regex]::Escape("<$ph>"), $val
                }
            }
            $txtPrev.Text = $script:tmpScript
        }.GetNewClosure())
    }

    $btnRunPS.Add_Click({
        $tempDir = Join-Path $env:TEMP "SPToolkit"
        if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }
        $safeName = ($CmdName -replace '[^\w\-]','_')
        $tempFile = Join-Path $tempDir "$safeName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
        $txtPrev.Text | Set-Content -Path $tempFile -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$tempFile`""
    }.GetNewClosure())

    $btnCopyR.Add_Click({
        if ($txtPrev.Text -ne "") {
            [System.Windows.Forms.Clipboard]::SetText($txtPrev.Text)
            [System.Windows.Forms.MessageBox]::Show("Script copied to clipboard.","Done","OK","Information")
        }
    }.GetNewClosure())

    $btnCloseR.Add_Click({ $rf.Close() })
    $rf.CancelButton = $btnCloseR

    [void]$rf.ShowDialog()
    $rf.Dispose()
}

# ================================================================
# SHOW-EDITFORM: Add / Edit command
# ================================================================
function Show-EditForm {
    param([string]$EId="")
    $isE = $EId -ne ""
    $eCmd = $null
    if ($isE) {
        $eCmd = $global:Commands | Where-Object { $_.Id -eq $EId } | Select-Object -First 1
        if (-not $eCmd) { return }
    }

    $ef = New-Object System.Windows.Forms.Form
    $ef.Text = if ($isE) { "Edit Command" } else { "New Command" }
    $ef.Size = New-Object System.Drawing.Size(630, 590)
    $ef.StartPosition = "CenterParent"
    $ef.BackColor = $script:C_Gray
    $ef.Font = $script:FNormal
    $ef.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $ef.MaximizeBox = $false; $ef.MinimizeBox = $false

    $y = 12; $lW = 90; $cX = 100; $cW = 495

    $ef.Controls.Add((New-W95Lbl -Text "Name:" -X 8 -Y $y -W $lW -Bold))
    $tN = New-Object System.Windows.Forms.TextBox
    $tN.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tN.Size = New-Object System.Drawing.Size($cW, 22); $tN.Font = $script:FNormal
    if ($isE) { $tN.Text = $eCmd.Name }
    $ef.Controls.Add($tN); $y += 28

    $ef.Controls.Add((New-W95Lbl -Text "Category:" -X 8 -Y $y -W $lW -Bold))
    $tCat = New-Object System.Windows.Forms.ComboBox
    $tCat.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tCat.Size = New-Object System.Drawing.Size(190, 22); $tCat.Font = $script:FNormal
    $tCat.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $allCats = @("Modules","Connection","PnP Registration","Site Management","Permissions","Recycle Bin","Files","OneDrive","Tenant","Troubleshooting","Sharing","Other")
    $existCats = $global:Commands | ForEach-Object { $_.Category } | Sort-Object -Unique
    $merged = ($allCats + $existCats) | Sort-Object -Unique
    foreach ($c in $merged) { $tCat.Items.Add($c) | Out-Null }
    if ($isE) { $tCat.Text = $eCmd.Category }
    $ef.Controls.Add($tCat)

    $ef.Controls.Add((New-W95Lbl -Text "SubCat:" -X 310 -Y $y -W 50))
    $tSub = New-Object System.Windows.Forms.TextBox
    $tSub.Location = New-Object System.Drawing.Point(365, ($y-2))
    $tSub.Size = New-Object System.Drawing.Size(230, 22); $tSub.Font = $script:FNormal
    if ($isE) { $tSub.Text = $eCmd.SubCategory }
    $ef.Controls.Add($tSub); $y += 28

    $ef.Controls.Add((New-W95Lbl -Text "PS Version:" -X 8 -Y $y -W $lW -Bold))
    $tPSV = New-Object System.Windows.Forms.ComboBox
    $tPSV.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tPSV.Size = New-Object System.Drawing.Size(140, 22); $tPSV.Font = $script:FNormal
    $tPSV.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $tPSV.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $tPSV.Items.AddRange(@("5","7","5 & 7","7 (recommended)","N/A"))
    $tPSV.SelectedIndex = 2
    if ($isE) { $mi = $tPSV.Items.IndexOf($eCmd.PSVersion); if($mi -ge 0){$tPSV.SelectedIndex=$mi} }
    $ef.Controls.Add($tPSV); $y += 28

    $ef.Controls.Add((New-W95Lbl -Text "Description:" -X 8 -Y $y -W $lW -Bold))
    $tDesc = New-Object System.Windows.Forms.TextBox
    $tDesc.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tDesc.Size = New-Object System.Drawing.Size($cW, 48); $tDesc.Font = $script:FNormal
    $tDesc.Multiline = $true; $tDesc.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    if ($isE) { $tDesc.Text = $eCmd.Description }
    $ef.Controls.Add($tDesc); $y += 55

    $ef.Controls.Add((New-W95Lbl -Text "Script:" -X 8 -Y $y -W $lW -Bold))
    $tScr = New-Object System.Windows.Forms.TextBox
    $tScr.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tScr.Size = New-Object System.Drawing.Size($cW, 200); $tScr.Font = $script:FMono
    $tScr.Multiline = $true; $tScr.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    $tScr.WordWrap = $false; $tScr.AcceptsTab = $true
    $tScr.BackColor = $script:C_TermBG; $tScr.ForeColor = $script:C_TermFG
    if ($isE) { $tScr.Text = $eCmd.Script }
    $ef.Controls.Add($tScr); $y += 208

    $ef.Controls.Add((New-W95Lbl -Text "Tags:" -X 8 -Y $y -W $lW -Bold))
    $tTags = New-Object System.Windows.Forms.TextBox
    $tTags.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tTags.Size = New-Object System.Drawing.Size($cW, 22); $tTags.Font = $script:FNormal
    if ($isE) { $tTags.Text = $eCmd.Tags }
    $ef.Controls.Add($tTags); $y += 28

    $ef.Controls.Add((New-W95Lbl -Text "Notes:" -X 8 -Y $y -W $lW -Bold))
    $tNotes = New-Object System.Windows.Forms.TextBox
    $tNotes.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tNotes.Size = New-Object System.Drawing.Size($cW, 42); $tNotes.Font = $script:FNormal
    $tNotes.Multiline = $true
    if ($isE) { $tNotes.Text = $eCmd.Notes }
    $ef.Controls.Add($tNotes); $y += 52

    $bSave = New-W95Btn -Text "Save" -X 380 -Y $y -W 100 -H 28
    $bSave.Font = $script:FBold
    $ef.Controls.Add($bSave)
    $bCancel = New-W95Btn -Text "Cancel" -X 490 -Y $y -W 100 -H 28
    $ef.Controls.Add($bCancel)

    $bSave.Add_Click({
        if ($tN.Text.Trim() -eq "") {
            [System.Windows.Forms.MessageBox]::Show("Name is required.","Error","OK","Warning")
            return
        }
        $entry = New-CmdEntry -N $tN.Text.Trim() `
            -Cat $(if($tCat.Text.Trim()){$tCat.Text.Trim()}else{"Other"}) `
            -Sub $tSub.Text.Trim() -Desc $tDesc.Text.Trim() `
            -Scr $tScr.Text -PSV $tPSV.Text `
            -Tags $tTags.Text.Trim() -Notes $tNotes.Text.Trim() `
            -Id $(if($isE){$eCmd.Id}else{""})

        if ($isE) {
            for ($i = 0; $i -lt $global:Commands.Count; $i++) {
                if ($global:Commands[$i].Id -eq $eCmd.Id) { $global:Commands[$i] = $entry; break }
            }
        } else { $global:Commands.Add($entry) | Out-Null }
        Save-Database
        $ef.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $ef.Close()
    })
    $bCancel.Add_Click({ $ef.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $ef.Close() })
    $ef.AcceptButton = $bSave; $ef.CancelButton = $bCancel
    return $ef.ShowDialog()
}

# ================================================================
# MAIN FORM
# ================================================================
function Show-MainForm {
    Load-Database

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "SP Engineer Toolkit v2.0"
    $form.Size = New-Object System.Drawing.Size(1060, 730)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = $script:C_Gray
    $form.Font = $script:FNormal
    $form.MinimumSize = New-Object System.Drawing.Size(900, 600)
    $form.KeyPreview = $true

    # --- TITLE BAR ---
    $pnlTitle = New-Object System.Windows.Forms.Panel
    $pnlTitle.Dock = [System.Windows.Forms.DockStyle]::Top
    $pnlTitle.Height = 30
    $pnlTitle.BackColor = $script:C_Navy
    $form.Controls.Add($pnlTitle)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "  SP Engineer Toolkit v2.0 - Script Repository"
    $lblTitle.ForeColor = $script:C_White
    $lblTitle.Font = $script:FTitle
    $lblTitle.Dock = [System.Windows.Forms.DockStyle]::Fill
    $lblTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $pnlTitle.Controls.Add($lblTitle)

    # --- SEARCH PANEL ---
    $pnlSearch = New-Object System.Windows.Forms.Panel
    $pnlSearch.Dock = [System.Windows.Forms.DockStyle]::Top
    $pnlSearch.Height = 68
    $pnlSearch.BackColor = $script:C_Gray
    $form.Controls.Add($pnlSearch)

    $pnlSearch.Controls.Add((New-W95Lbl -Text "Search:" -X 10 -Y 10 -W 50 -Bold))

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(63, 7)
    $txtSearch.Size = New-Object System.Drawing.Size(380, 22)
    $txtSearch.Font = $script:FNormal
    $txtSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $pnlSearch.Controls.Add($txtSearch)

    $btnSearch = New-W95Btn -Text "Search" -X 450 -Y 6 -W 75
    $pnlSearch.Controls.Add($btnSearch)
    $btnClear = New-W95Btn -Text "Clear" -X 530 -Y 6 -W 75
    $pnlSearch.Controls.Add($btnClear)

    $pnlSearch.Controls.Add((New-W95Lbl -Text "Category:" -X 10 -Y 40 -W 65 -Bold))

    $cmbCat = New-Object System.Windows.Forms.ComboBox
    $cmbCat.Location = New-Object System.Drawing.Point(78, 37)
    $cmbCat.Size = New-Object System.Drawing.Size(170, 22); $cmbCat.Font = $script:FNormal
    $cmbCat.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbCat.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $pnlSearch.Controls.Add($cmbCat)

    $pnlSearch.Controls.Add((New-W95Lbl -Text "PS Ver:" -X 260 -Y 40 -W 50 -Bold))

    $cmbPS = New-Object System.Windows.Forms.ComboBox
    $cmbPS.Location = New-Object System.Drawing.Point(313, 37)
    $cmbPS.Size = New-Object System.Drawing.Size(100, 22); $cmbPS.Font = $script:FNormal
    $cmbPS.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbPS.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $cmbPS.Items.AddRange(@("All","5","7","5 & 7","N/A"))
    $cmbPS.SelectedIndex = 0
    $pnlSearch.Controls.Add($cmbPS)

    $lblCount = New-W95Lbl -Text "Results: 0" -X 620 -Y 10 -W 160 -Bold
    $pnlSearch.Controls.Add($lblCount)

    $btnAdd    = New-W95Btn -Text "New"    -X 620 -Y 36 -W 75
    $btnEdit   = New-W95Btn -Text "Edit"   -X 700 -Y 36 -W 75
    $btnDel    = New-W95Btn -Text "Delete" -X 780 -Y 36 -W 75
    $btnExport = New-W95Btn -Text "Export" -X 860 -Y 36 -W 75
    $btnImport = New-W95Btn -Text "Import" -X 940 -Y 36 -W 75
    $pnlSearch.Controls.Add($btnAdd)
    $pnlSearch.Controls.Add($btnEdit)
    $pnlSearch.Controls.Add($btnDel)
    $pnlSearch.Controls.Add($btnExport)
    $pnlSearch.Controls.Add($btnImport)

    # --- STATUS BAR ---
    $statusBar = New-Object System.Windows.Forms.StatusBar
    $statusBar.Text = " SP Engineer Toolkit v2.0 | Ismael Najera | Commands: $($global:Commands.Count)"
    $statusBar.Font = $script:FNormal
    $form.Controls.Add($statusBar)

    # --- SPLIT CONTAINER ---
    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Dock = [System.Windows.Forms.DockStyle]::Fill
    $split.Orientation = [System.Windows.Forms.Orientation]::Horizontal
    $split.SplitterDistance = 250
    $split.BackColor = $script:C_Gray
    $split.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $form.Controls.Add($split)
    $split.BringToFront()

    # --- LISTVIEW ---
    $lv = New-Object System.Windows.Forms.ListView
    $lv.Dock = [System.Windows.Forms.DockStyle]::Fill
    $lv.View = [System.Windows.Forms.View]::Details
    $lv.FullRowSelect = $true; $lv.GridLines = $true
    $lv.Font = $script:FNormal; $lv.BackColor = $script:C_White
    $lv.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $lv.MultiSelect = $false; $lv.HideSelection = $false
    $lv.Columns.Add("Name", 210) | Out-Null
    $lv.Columns.Add("Category", 120) | Out-Null
    $lv.Columns.Add("SubCategory", 110) | Out-Null
    $lv.Columns.Add("PS Ver", 95) | Out-Null
    $lv.Columns.Add("Description", 430) | Out-Null
    $split.Panel1.Controls.Add($lv)

    # --- CONTEXT MENU ---
    $ctx = New-Object System.Windows.Forms.ContextMenu
    $ctxCopy = New-Object System.Windows.Forms.MenuItem("Copy Script")
    $ctxSavePS1 = New-Object System.Windows.Forms.MenuItem("Save as .ps1")
    $ctxRun  = New-Object System.Windows.Forms.MenuItem("Run...")
    $ctxEdit = New-Object System.Windows.Forms.MenuItem("Edit")
    $ctxDel  = New-Object System.Windows.Forms.MenuItem("Delete")
    $ctx.MenuItems.AddRange(@($ctxCopy, $ctxSavePS1, $ctxRun, $ctxEdit, $ctxDel))
    $lv.ContextMenu = $ctx

    # --- DETAIL PANEL ---
    $pnlDetail = New-Object System.Windows.Forms.Panel
    $pnlDetail.Dock = [System.Windows.Forms.DockStyle]::Fill
    $pnlDetail.BackColor = $script:C_Gray
    $split.Panel2.Controls.Add($pnlDetail)

    $pnlInfo = New-Object System.Windows.Forms.Panel
    $pnlInfo.Dock = [System.Windows.Forms.DockStyle]::Top
    $pnlInfo.Height = 52
    $pnlInfo.BackColor = $script:C_Gray
    $pnlDetail.Controls.Add($pnlInfo)

    $lblDName = New-Object System.Windows.Forms.Label
    $lblDName.Text = "Select a command to view details"
    $lblDName.Location = New-Object System.Drawing.Point(6, 3)
    $lblDName.Size = New-Object System.Drawing.Size(500, 16)
    $lblDName.Font = $script:FBold; $lblDName.ForeColor = $script:C_Navy
    $pnlInfo.Controls.Add($lblDName)

    $lblDTags = New-Object System.Windows.Forms.Label
    $lblDTags.Text = ""
    $lblDTags.Location = New-Object System.Drawing.Point(6, 20)
    $lblDTags.Size = New-Object System.Drawing.Size(500, 14)
    $lblDTags.Font = $script:FNormal; $lblDTags.ForeColor = $script:C_DarkGray
    $pnlInfo.Controls.Add($lblDTags)

    $lblDNotes = New-Object System.Windows.Forms.Label
    $lblDNotes.Text = ""
    $lblDNotes.Location = New-Object System.Drawing.Point(6, 35)
    $lblDNotes.Size = New-Object System.Drawing.Size(500, 14)
    $lblDNotes.Font = $script:FNormal; $lblDNotes.ForeColor = $script:C_DarkRed
    $pnlInfo.Controls.Add($lblDNotes)

    # === NEW BUTTONS: Run, Save .ps1, Copy Script ===
    $btnRun = New-W95Btn -Text ([char]9654 + " Run") -X 520 -Y 6 -W 100
    $btnRun.Font = $script:FBold
    $pnlInfo.Controls.Add($btnRun)

    $btnSavePS1 = New-W95Btn -Text "Save .ps1" -X 630 -Y 6 -W 100
    $btnSavePS1.Font = $script:FBold
    $pnlInfo.Controls.Add($btnSavePS1)

    $btnCopy = New-W95Btn -Text "Copy Script" -X 740 -Y 6 -W 110
    $btnCopy.Font = $script:FBold
    $pnlInfo.Controls.Add($btnCopy)

    # --- Script display ---
    $txtScript = New-Object System.Windows.Forms.RichTextBox
    $txtScript.Dock = [System.Windows.Forms.DockStyle]::Fill
    $txtScript.Font = $script:FMono
    $txtScript.BackColor = $script:C_TermBG
    $txtScript.ForeColor = $script:C_TermFG
    $txtScript.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $txtScript.ReadOnly = $true; $txtScript.WordWrap = $false
    $txtScript.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Both
    $pnlDetail.Controls.Add($txtScript)
    $txtScript.BringToFront()

    # === INTERNAL FUNCTIONS ===

    function Update-CatFilter {
        $sel = $cmbCat.Text
        $cmbCat.Items.Clear()
        $cmbCat.Items.Add("All") | Out-Null
        $cats = $global:Commands | ForEach-Object { $_.Category } | Sort-Object -Unique
        foreach ($c in $cats) { $cmbCat.Items.Add($c) | Out-Null }
        $idx = $cmbCat.Items.IndexOf($sel)
        $cmbCat.SelectedIndex = if ($idx -ge 0) { $idx } else { 0 }
    }

    function Update-LV {
        param([string]$S="",[string]$CF="All",[string]$PF="All")
        $lv.Items.Clear()
        $res = $global:Commands
        if ($CF -ne "All") { $res = $res | Where-Object { $_.Category -eq $CF } }
        if ($PF -ne "All") { $res = $res | Where-Object { $_.PSVersion -like "*$PF*" } }
        if ($S -ne "") {
            $sl = $S.ToLower()
            $res = $res | Where-Object {
                $_.Name.ToLower().Contains($sl) -or $_.Description.ToLower().Contains($sl) -or
                $_.Script.ToLower().Contains($sl) -or $_.Tags.ToLower().Contains($sl) -or
                $_.Category.ToLower().Contains($sl) -or $_.SubCategory.ToLower().Contains($sl) -or
                $_.Notes.ToLower().Contains($sl)
            }
        }
        foreach ($cmd in $res) {
            $item = New-Object System.Windows.Forms.ListViewItem($cmd.Name)
            $item.SubItems.Add($cmd.Category) | Out-Null
            $item.SubItems.Add($cmd.SubCategory) | Out-Null
            $item.SubItems.Add($cmd.PSVersion) | Out-Null
            $item.SubItems.Add($cmd.Description) | Out-Null
            $item.Tag = $cmd.Id
            $lv.Items.Add($item) | Out-Null
        }
        $lblCount.Text = "Results: $($lv.Items.Count)"
        $statusBar.Text = " SP Engineer Toolkit v2.0 | Total: $($global:Commands.Count) | Showing: $($lv.Items.Count)"
    }

    function Show-Detail ([string]$Id) {
        $cmd = $global:Commands | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
        if ($cmd) {
            $lblDName.Text = "$($cmd.Name)  [$($cmd.Category) > $($cmd.SubCategory)]  [PS $($cmd.PSVersion)]"
            $lblDTags.Text = "Tags: $($cmd.Tags)"
            $lblDNotes.Text = "$($cmd.Notes)"
            $txtScript.Text = $cmd.Script
        }
    }

    function Get-SelectedId {
        if ($lv.SelectedItems.Count -gt 0) { return $lv.SelectedItems[0].Tag }
        return $null
    }

    function Copy-SelectedScript {
        $id = Get-SelectedId
        if ($id) {
            $cmd = $global:Commands | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($cmd) {
                [System.Windows.Forms.Clipboard]::SetText($cmd.Script)
                $statusBar.Text = " Script copied: $($cmd.Name)"
            }
        }
    }

    # === EVENT HANDLERS ===
    $doSearch = { Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text }

    $btnSearch.Add_Click($doSearch)
    $txtSearch.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text
            $_.SuppressKeyPress = $true
        }
    })

    $btnClear.Add_Click({
        $txtSearch.Text = ""; $cmbCat.SelectedIndex = 0; $cmbPS.SelectedIndex = 0
        Update-LV
        $lblDName.Text = "Select a command to view details"
        $lblDTags.Text = ""; $lblDNotes.Text = ""; $txtScript.Text = ""
    })

    $cmbCat.Add_SelectedIndexChanged($doSearch)
    $cmbPS.Add_SelectedIndexChanged($doSearch)

    $lv.Add_SelectedIndexChanged({
        $id = Get-SelectedId
        if ($id) { Show-Detail $id }
    })

    $lv.Add_DoubleClick({ Copy-SelectedScript })

    # --- Copy Script ---
    $btnCopy.Add_Click({
        if ($txtScript.Text -ne "") {
            [System.Windows.Forms.Clipboard]::SetText($txtScript.Text)
            $statusBar.Text = " Script copied to clipboard"
        }
    })

    # --- Save .ps1 ---
    $btnSavePS1.Add_Click({
        $id = Get-SelectedId
        if ($id) {
            $cmd = $global:Commands | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($cmd) {
                $sfd = New-Object System.Windows.Forms.SaveFileDialog
                $safeName = $cmd.Name -replace '[^\w\-]','_'
                $sfd.FileName = "$safeName.ps1"
                $sfd.Filter = "PowerShell Script (*.ps1)|*.ps1|All files (*.*)|*.*"
                $sfd.Title = "Save Script as .ps1"
                if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $cmd.Script | Set-Content -Path $sfd.FileName -Encoding UTF8
                    $statusBar.Text = " Saved: $($sfd.FileName)"
                    [System.Windows.Forms.MessageBox]::Show("Script saved as:`n$($sfd.FileName)","Saved","OK","Information")
                }
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Select a command first.","Info","OK","Information")
        }
    })

    # --- Run ---
    $btnRun.Add_Click({
        $id = Get-SelectedId
        if ($id) {
            $cmd = $global:Commands | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($cmd) { Show-RunForm -ScriptText $cmd.Script -CmdName $cmd.Name }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Select a command first.","Info","OK","Information")
        }
    })

    # --- New / Edit / Delete ---
    $btnAdd.Add_Click({
        $r = Show-EditForm
        if ($r -eq [System.Windows.Forms.DialogResult]::OK) {
            Update-CatFilter
            Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text
        }
    })

    $btnEdit.Add_Click({
        $id = Get-SelectedId
        if ($id) {
            $r = Show-EditForm -EId $id
            if ($r -eq [System.Windows.Forms.DialogResult]::OK) {
                Update-CatFilter
                Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text
                Show-Detail $id
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Select a command first.","Info","OK","Information")
        }
    })

    $btnDel.Add_Click({
        $id = Get-SelectedId
        if ($id) {
            $cmd = $global:Commands | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            $cf = [System.Windows.Forms.MessageBox]::Show(
                "Delete '$($cmd.Name)'?`n`nThis action cannot be undone.",
                "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($cf -eq [System.Windows.Forms.DialogResult]::Yes) {
                $rem = $global:Commands | Where-Object { $_.Id -eq $id } | Select-Object -First 1
                $global:Commands.Remove($rem)
                Save-Database; Update-CatFilter
                Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text
                $txtScript.Text = ""; $lblDName.Text = "Select a command"; $lblDTags.Text = ""; $lblDNotes.Text = ""
            }
        }
    })

    # --- Export (CSV) ---
    $btnExport.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "CSV (*.csv)|*.csv|All files (*.*)|*.*"
        $sfd.FileName = "SP_Toolkit_Export_$(Get-Date -Format 'yyyyMMdd').csv"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $global:Commands.ToArray() | Export-Csv -Path $sfd.FileName -NoTypeInformation -Encoding UTF8
            $statusBar.Text = " Exported: $($sfd.FileName)"
            [System.Windows.Forms.MessageBox]::Show("Export completed.","Done","OK","Information")
        }
    })

    # --- Import (CSV with JSON fallback) ---
    $btnImport.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "CSV (*.csv)|*.csv|JSON (*.json)|*.json|All files (*.*)|*.*"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $data = $null
                if ($ofd.FileName -like "*.json") {
                    $data = Get-Content -Path $ofd.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
                } else {
                    $data = Import-Csv -Path $ofd.FileName -Encoding UTF8
                }
                $count = 0
                foreach ($item in $data) {
                    # Assign new ID to avoid duplicates
                    $entry = New-CmdEntry -N $item.Name -Cat $item.Category -Sub $item.SubCategory `
                        -Desc $item.Description -Scr $item.Script -PSV $item.PSVersion `
                        -Tags $item.Tags -Notes $item.Notes
                    $global:Commands.Add($entry) | Out-Null
                    $count++
                }
                Save-Database; Update-CatFilter
                Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text
                $statusBar.Text = " Imported: $count commands"
                [System.Windows.Forms.MessageBox]::Show("$count commands imported.","Done","OK","Information")
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Import error: $($_.Exception.Message)","Error","OK","Error")
            }
        }
    })

    # --- Context Menu ---
    $ctxCopy.Add_Click({ Copy-SelectedScript })
    $ctxSavePS1.Add_Click({ $btnSavePS1.PerformClick() })
    $ctxRun.Add_Click({ $btnRun.PerformClick() })
    $ctxEdit.Add_Click({ $btnEdit.PerformClick() })
    $ctxDel.Add_Click({ $btnDel.PerformClick() })

    # --- Keyboard Shortcuts ---
    $form.Add_KeyDown({
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::N) { $btnAdd.PerformClick(); $_.Handled = $true }
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::F) { $txtSearch.Focus(); $_.Handled = $true }
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::R) { $btnRun.PerformClick(); $_.Handled = $true }
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::F5) {
            Update-CatFilter; Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text; $_.Handled = $true
        }
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Delete -and $lv.Focused) { $btnDel.PerformClick(); $_.Handled = $true }
    })

    # === INITIALIZE ===
    Update-CatFilter
    Update-LV

    [void]$form.ShowDialog()
    $form.Dispose()
}

# === LAUNCH ===
Show-MainForm