# ============================================================================
# ScriptHub.Catalog.ps1 - Script listing / catalog only
# Part of ScriptHub. Loaded by ScriptHub.UI.ps1 - do not run this file alone.
# Author: Ismael Najera
#
# HOW TO ADD A NEW SCRIPT:
#   1. A colleague submits the request form published on the ScriptHub site.
#   2. The request is reviewed, validated and approved.
#   3. A new New-CmdEntry block is appended to this file only.
#      No other file needs to be modified.
# ============================================================================

function Get-ScriptHubCatalog {

    $d = @()

    # ------------------------------------------------------------------
    # MODULES
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "SharePoint Online Management Shell" -Cat "Modules" -Sub "Installation" `
        -Desc "Official Microsoft module for SharePoint Online administration." `
        -PSV "5 & 7" -Tags "module, SPO, install, admin" `
        -Notes "Requires SharePoint Admin permissions. On PS7 some legacy cmdlets may need -UseWindowsPowerShell." `
        -Scr @'
# Install the module
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force

# Verify installation
Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable

# Import module
Import-Module Microsoft.Online.SharePoint.PowerShell
'@

    $d += New-CmdEntry -N "PnP PowerShell" -Cat "Modules" -Sub "Installation" `
        -Desc "Community-driven PnP module with 600+ cmdlets for SharePoint Online." `
        -PSV "7 (recommended)" -Tags "module, PnP, install, community" `
        -Notes "PnP.PowerShell targets PS7+. SharePointPnPPowerShellOnline is the legacy PS5 version." `
        -Scr @'
# Install PnP PowerShell (PS7 recommended)
Install-Module -Name PnP.PowerShell -Force

# For PS5 (legacy version)
Install-Module -Name SharePointPnPPowerShellOnline -Force

# Verify installed version
Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version
'@

    $d += New-CmdEntry -N "Microsoft Graph PowerShell SDK" -Cat "Modules" -Sub "Installation" `
        -Desc "SDK to interact with Microsoft Graph API. Manages users, groups, OneDrive, Entra ID." `
        -PSV "5 & 7" -Tags "module, graph, API, entra, install" `
        -Notes "Install only the sub-modules you need to reduce load time." `
        -Scr @'
# Install Graph modules
Install-Module Microsoft.Graph -Force

# Or install only specific sub-modules
Install-Module Microsoft.Graph.Sites -Force
Install-Module Microsoft.Graph.Users -Force
Install-Module Microsoft.Graph.Groups -Force

# Verify
Get-Module Microsoft.Graph* -ListAvailable | Select-Object Name, Version
'@

    $d += New-CmdEntry -N "Exchange Online Management" -Cat "Modules" -Sub "Installation" `
        -Desc "Module to manage Exchange Online, Security and Compliance and M365 groups." `
        -PSV "5 & 7" -Tags "module, exchange, groups, M365" `
        -Notes "M365 groups are linked to SPO team sites." `
        -Scr @'
# Install
Install-Module -Name ExchangeOnlineManagement -Force

# Connect
Connect-ExchangeOnline -UserPrincipalName admin@<TenantName>.onmicrosoft.com

# Check M365 groups (which create SPO team sites)
Get-UnifiedGroup -Identity '<GroupName>' | Format-List
'@

    $d += New-CmdEntry -N "Microsoft Teams PowerShell" -Cat "Modules" -Sub "Installation" `
        -Desc "Module to administer Microsoft Teams: teams, channels, policies and meetings." `
        -PSV "5 & 7" -Tags "module, teams, install, admin" `
        -Notes "Requires Teams Administrator or Global Administrator role." `
        -Scr @'
# Install
Install-Module -Name MicrosoftTeams -Force

# Connect
Connect-MicrosoftTeams

# Verify connection
Get-CsTenant | Select-Object DisplayName, TenantId
'@

    $d += New-CmdEntry -N "Azure Az PowerShell" -Cat "Modules" -Sub "Installation" `
        -Desc "Az module to manage Azure subscriptions, resources and role assignments." `
        -PSV "7 (recommended)" -Tags "module, azure, az, install" `
        -Notes "Az replaces the deprecated AzureRM module. Do not install both in the same session." `
        -Scr @'
# Install
Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber

# Connect
Connect-AzAccount

# List subscriptions and select one
Get-AzSubscription | Select-Object Name, Id, State
Set-AzContext -SubscriptionId '<SubscriptionId>'
'@

    # ------------------------------------------------------------------
    # PnP REGISTRATION
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Register PnP Entra ID App (Interactive)" -Cat "PnP Registration" -Sub "App Registration" `
        -Desc "Registers an Entra ID app for PnP PowerShell with interactive login." `
        -PSV "7" -Tags "PnP, registration, app, entra, client ID, application ID" `
        -Notes "The generated Application ID is required by Connect-PnPOnline -Interactive -ClientId." `
        -Scr @'
# Register app for PnP with interactive login
# IMPORTANT: Requires Global Admin or Application Admin permissions

Register-PnPEntraIDAppForInteractiveLogin `
    -ApplicationName 'PnP-PowerShell-App' `
    -Tenant '<TenantName>.onmicrosoft.com' `
    -Interactive

# The command opens the browser for authentication
# On completion it displays the Application (Client) ID
# SAVE this ID - it is required by Connect-PnPOnline
'@

    $d += New-CmdEntry -N "Register PnP Azure AD App (Certificate)" -Cat "PnP Registration" -Sub "App Registration" `
        -Desc "Registers an Entra ID app with certificate authentication. Ideal for automation." `
        -PSV "7" -Tags "PnP, registration, certificate, app, automation" `
        -Notes "Use -Store CurrentUser to save the certificate in the user certificate store." `
        -Scr @'
# Register app with auto-generated certificate
Register-PnPAzureADApp `
    -ApplicationName 'PnP-Automation' `
    -Tenant '<TenantName>.onmicrosoft.com' `
    -Store CurrentUser `
    -SharePointApplicationPermissions 'Sites.FullControl.All' `
    -GraphApplicationPermissions 'Group.ReadWrite.All' `
    -Interactive

# Connect using the certificate
Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com' `
    -ClientId '<AppId>' `
    -Tenant '<TenantName>.onmicrosoft.com' `
    -Thumbprint '<CertThumbprint>'
'@

    $d += New-CmdEntry -N "Get registered PnP App ID" -Cat "PnP Registration" -Sub "Verification" `
        -Desc "Verify and retrieve the Application ID of PnP apps already registered in Entra ID." `
        -PSV "7" -Tags "PnP, app ID, verify, entra, graph" `
        -Notes "AppId = Application (Client) ID. Id = Object ID. For PnP use the AppId." `
        -Scr @'
# Option 1: Search app by name in Entra ID via Graph
Connect-MgGraph -Scopes 'Application.Read.All'

Get-MgApplication -Filter "displayName eq 'PnP-PowerShell-App'" |
    Select-Object DisplayName, AppId, Id

# Option 2: List all apps starting with 'PnP'
Get-MgApplication -Filter "startswith(displayName,'PnP')" |
    Select-Object DisplayName, AppId

# Option 3: From the portal
# Entra ID > App registrations > Search by name > Application (client) ID
'@

    # ------------------------------------------------------------------
    # CONNECTION
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Connect-SPOService" -Cat "Connection" -Sub "SPO Admin" `
        -Desc "Connects to the SharePoint Online admin center using the SPO module." `
        -PSV "5 & 7" -Tags "connection, SPO, admin, tenant" `
        -Notes "URL must be the admin center: https://tenant-admin.sharepoint.com" `
        -Scr @'
# Standard connection (opens login prompt)
Connect-SPOService -Url 'https://<TenantName>-admin.sharepoint.com'

# Verify connection
Get-SPOTenant | Select-Object StorageQuota, SharingCapability
'@

    $d += New-CmdEntry -N "Connect-PnPOnline (Methods)" -Cat "Connection" -Sub "PnP" `
        -Desc "Different connection methods with PnP PowerShell." `
        -PSV "7" -Tags "connection, PnP, interactive, certificate, credentials" `
        -Notes "For -Interactive you need the ClientId of your registered app." `
        -Scr @'
# Method 1: Interactive with registered app (RECOMMENDED)
Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -Interactive `
    -ClientId '<AppId>'

# Method 2: With credentials (legacy)
$cred = Get-Credential
Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -Credentials $cred

# Method 3: With certificate (automation)
Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com' `
    -ClientId '<AppId>' -Tenant '<TenantName>.onmicrosoft.com' `
    -Thumbprint '<CertThumbprint>'

# Verify connection
Get-PnPContext | Select-Object Url
'@

    $d += New-CmdEntry -N "Connect to all M365 workloads" -Cat "Connection" -Sub "Multi-workload" `
        -Desc "Single block to connect to SPO, PnP, Exchange, Teams, Graph and Azure." `
        -PSV "7 (recommended)" -Tags "connection, exchange, teams, graph, azure, spo" `
        -Notes "Connect only to the workloads you need. Each connection is independent." `
        -Scr @'
# SharePoint Online admin
Connect-SPOService -Url 'https://<TenantName>-admin.sharepoint.com'

# PnP (site level)
Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Interactive -ClientId '<AppId>'

# Exchange Online
Connect-ExchangeOnline -UserPrincipalName '<AdminEmail>'

# Security and Compliance (Purview)
Connect-IPPSSession -UserPrincipalName '<AdminEmail>'

# Microsoft Teams
Connect-MicrosoftTeams

# Microsoft Graph
Connect-MgGraph -Scopes 'User.Read.All','Group.Read.All','Directory.Read.All'

# Azure
Connect-AzAccount -Tenant '<TenantId>'
'@

    # ------------------------------------------------------------------
    # SITE MANAGEMENT
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Get-SPOSite (Site info)" -Cat "Site Management" -Sub "Query" `
        -Desc "Retrieve SharePoint Online site information." `
        -PSV "5 & 7" -Tags "site, SPO, info, sharing, template, quota" `
        -Notes "GROUP#0 = M365 team sites. SITEPAGEPUBLISHING#0 = communication sites." `
        -Scr @'
# Get all sites
Get-SPOSite -Limit All | Select-Object Url, Template, StorageUsageCurrent, SharingCapability

# Specific site with detail
Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Detailed | Format-List

# Filter by template
Get-SPOSite -Limit All -Template 'GROUP#0' | Select-Object Url, GroupId

# Sites with external sharing enabled
Get-SPOSite -Limit All | Where-Object { $_.SharingCapability -ne 'Disabled' } |
    Select-Object Url, SharingCapability
'@

    $d += New-CmdEntry -N "Set-SPOSite (Modify site)" -Cat "Site Management" -Sub "Configuration" `
        -Desc "Modify site configuration: sharing, storage quota and lock state." `
        -PSV "5 & 7" -Tags "site, sharing, quota, lock, configuration" `
        -Notes "Site SharingCapability cannot exceed the tenant level setting." `
        -Scr @'
# Change sharing capability
Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -SharingCapability ExternalUserAndGuestSharing

# SharingCapability values:
# Disabled                        - No external sharing
# ExistingExternalUserSharingOnly - Existing guests only
# ExternalUserSharingOnly         - New and existing guests
# ExternalUserAndGuestSharing     - Anyone (anonymous links)

# Change storage quota
Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -StorageQuota 5120 -StorageQuotaWarningLevel 4096

# Lock / Unlock site (ReadOnly | Unlock | NoAccess)
Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -LockState NoAccess
'@

    # ------------------------------------------------------------------
    # PERMISSIONS
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Site Collection Admin (Add/Remove)" -Cat "Permissions" -Sub "Admin" `
        -Desc "Add or remove site collection administrators." `
        -PSV "5 & 7" -Tags "permissions, admin, site collection, access" `
        -Notes "Being Site Collection Admin grants full control over the site." `
        -Scr @'
# Add Site Collection Admin via SPO
Set-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -LoginName '<UserEmail>' `
    -IsSiteCollectionAdmin $true

# Remove Site Collection Admin
Set-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -LoginName '<UserEmail>' `
    -IsSiteCollectionAdmin $false

# Via PnP - List current admins
Get-PnPSiteCollectionAdmin

# Via PnP - Add admin
Add-PnPSiteCollectionAdmin -Owners '<UserEmail>'
'@

    $d += New-CmdEntry -N "Verify user permissions" -Cat "Permissions" -Sub "Query" `
        -Desc "Check what permissions a user has on a site or list." `
        -PSV "5 & 7" -Tags "permissions, user, verify, roles, access" `
        -Notes "HasUniqueRoleAssignments true means broken inheritance (unique permissions)." `
        -Scr @'
# Get user info on a site
Get-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -LoginName '<UserEmail>'

# List all users on a site
Get-SPOUser -Site 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Limit All

# PnP - Check permissions on a site
Get-PnPWeb -Includes RoleAssignments

# PnP - Permissions on a list/library
Get-PnPList -Identity 'Documents' -Includes RoleAssignments, HasUniqueRoleAssignments
'@

    $d += New-CmdEntry -N "User Information List - Cleanup" -Cat "Permissions" -Sub "Troubleshooting" `
        -Desc "Completely remove a user from the User Information List and re-add them." `
        -PSV "7" -Tags "UIL, user, cleanup, re-add, permissions, troubleshooting" `
        -Notes "WARNING: This removes the user from ALL site groups. Reassign permissions afterwards." `
        -Scr @'
# Step 1: Get the user ID in the UIL
$user = Get-PnPUser | Where-Object { $_.Email -eq '<UserEmail>' }
$user | Select-Object Id, Title, Email, LoginName

# Step 2: Remove user from the UIL
Remove-PnPUser -Identity $user.Id -Force

# Step 3: Re-add (auto re-added on next access) or force it
New-PnPUser -LoginName '<UserEmail>'

# Step 4: Verify
Get-PnPUser | Where-Object { $_.Email -eq '<UserEmail>' }
'@

    # ------------------------------------------------------------------
    # RECYCLE BIN
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Recycle Bin - Restore items" -Cat "Recycle Bin" -Sub "Restore" `
        -Desc "Search and restore items from first and second stage recycle bin." `
        -PSV "7" -Tags "recycle bin, restore, delete, recover" `
        -Notes "Second stage items are those deleted from first stage. Max retention: 93 days total." `
        -Scr @'
# List items in recycle bin (first stage)
Get-PnPRecycleBinItem | Select-Object Title, ItemType, DeletedByEmail, DeletedDate, ItemState | Format-Table

# Search for a specific file
Get-PnPRecycleBinItem | Where-Object { $_.Title -like '*<SearchTerm>*' }

# Restore specific item by ID
Restore-PnPRecycleBinItem -Identity '<ItemGuid>' -Force

# Restore ALL items (USE WITH CAUTION)
Get-PnPRecycleBinItem | Restore-PnPRecycleBinItem -Force

# Second stage recycle bin (admin)
Get-PnPRecycleBinItem -SecondStage
Get-PnPRecycleBinItem -SecondStage |
    Where-Object { $_.Title -like '*<SearchTerm>*' } |
    Restore-PnPRecycleBinItem -Force
'@

    # ------------------------------------------------------------------
    # FILES
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Move/Copy files (PnP)" -Cat "Files" -Sub "Operations" `
        -Desc "Move and copy files/folders between libraries or sites using PnP." `
        -PSV "7" -Tags "files, move, copy, folder, library" `
        -Notes "URLs are server-relative. For cross-site, both sites must be in the same tenant." `
        -Scr @'
# Copy file
Copy-PnPFile `
    -SourceUrl '/sites/<SourceSite>/Shared Documents/file.docx' `
    -TargetUrl '/sites/<TargetSite>/Shared Documents/file.docx' `
    -Force

# Move file
Move-PnPFile `
    -SourceUrl '/sites/<SiteName>/Shared Documents/file.docx' `
    -TargetUrl '/sites/<SiteName>/Shared Documents/Archive/file.docx' `
    -Force

# Move entire folder
Move-PnPFolder `
    -Folder 'Shared Documents/OldFolder' `
    -TargetFolder 'Shared Documents/Archive'
'@

    $d += New-CmdEntry -N "Version History - Configure" -Cat "Files" -Sub "Versioning" `
        -Desc "Configure and verify version history on document libraries." `
        -PSV "7" -Tags "versions, history, library, versioning" `
        -Notes "Default limit: 500 major versions." `
        -Scr @'
# Check version settings
Get-PnPList -Identity 'Documents' |
    Select-Object Title, EnableVersioning, MajorVersionLimit, EnableMinorVersions

# Enable versioning
Set-PnPList -Identity 'Documents' `
    -EnableVersioning $true `
    -MajorVersions 500

# Enable minor versions
Set-PnPList -Identity 'Documents' `
    -EnableMinorVersions $true `
    -MajorVersions 500 `
    -MinorVersions 10

# View file versions
Get-PnPFileVersion -Url '/sites/<SiteName>/Shared Documents/file.docx'
'@

    # ------------------------------------------------------------------
    # ONEDRIVE
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "OneDrive Admin Access" -Cat "OneDrive" -Sub "Admin" `
        -Desc "Grant administrative access to a user OneDrive and browse its recycle bin." `
        -PSV "5 & 7" -Tags "onedrive, admin, access, provision, personal site, recycle bin" `
        -Notes "Append the layouts path to reach the recycle bin instead of the default library view." `
        -Scr @'
# Grant admin access to a user OneDrive
Set-SPOUser `
    -Site 'https://<TenantName>-my.sharepoint.com/personal/<User_Domain_Com>' `
    -LoginName '<AdminEmail>' `
    -IsSiteCollectionAdmin $true

# Provision OneDrive for a user
Request-SPOPersonalSite -UserEmails @('<UserEmail>')

# Browse the recycle bin of that OneDrive (append to the personal site URL)
# /_layouts/15/RecycleBin.aspx        -> first stage
# /_layouts/15/AdminRecycleBin.aspx   -> second stage
'@

    $d += New-CmdEntry -N "OneDrive usage report (Graph)" -Cat "OneDrive" -Sub "Reporting" `
        -Desc "Export OneDrive usage and storage consumption per user." `
        -PSV "7" -Tags "onedrive, report, storage, graph, usage" `
        -Notes "Reports may be anonymized if the tenant privacy setting is enabled." `
        -Scr @'
Connect-MgGraph -Scopes 'Reports.Read.All'

# OneDrive usage detail (period: D7, D30, D90, D180)
Get-MgReportOneDriveUsageAccountDetail -Period 'D30' -OutFile 'C:\Temp\OneDriveUsage.csv'

# SharePoint site usage detail
Get-MgReportSharePointSiteUsageDetail -Period 'D30' -OutFile 'C:\Temp\SPOSiteUsage.csv'
'@

    # ------------------------------------------------------------------
    # TENANT
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Get-SPOTenant (Tenant Config)" -Cat "Tenant" -Sub "Configuration" `
        -Desc "Retrieve the global SharePoint Online tenant configuration." `
        -PSV "5 & 7" -Tags "tenant, configuration, sharing, global" `
        -Notes "Tenant config is the ceiling for each site configuration." `
        -Scr @'
# Get full tenant configuration
Get-SPOTenant | Format-List

# Key properties for troubleshooting
Get-SPOTenant | Select-Object `
    SharingCapability, `
    DefaultSharingLinkType, `
    FileAnonymousLinkType, `
    FolderAnonymousLinkType, `
    RequireAcceptingAccountMatchInvitedAccount, `
    ExternalUserExpirationRequired, `
    ExternalUserExpireInDays, `
    OneDriveSharingCapability, `
    EnableGuestSignInAcceleration
'@

    # ------------------------------------------------------------------
    # SHARING
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "External Sharing - Verify and configure" -Cat "Sharing" -Sub "External" `
        -Desc "Verify and modify external sharing configuration at tenant and site level." `
        -PSV "5 & 7" -Tags "sharing, external, guest, invitation, B2B" `
        -Notes "Hierarchy: Disabled, ExistingExternalUserSharingOnly, ExternalUserSharingOnly, ExternalUserAndGuestSharing." `
        -Scr @'
# Tenant level
Get-SPOTenant | Select-Object SharingCapability, OneDriveSharingCapability

# Site level
Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' |
    Select-Object Url, SharingCapability

# Change site sharing
Set-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' `
    -SharingCapability ExternalUserSharingOnly

# Check existing guests
Get-SPOExternalUser -SiteUrl 'https://<TenantName>.sharepoint.com/sites/<SiteName>' |
    Select-Object DisplayName, AcceptedAs, InvitedAs, WhenCreated

# Remove external guest
Remove-SPOExternalUser -UniqueIDs @('<ExternalUserID>')
'@

    # ------------------------------------------------------------------
    # EXCHANGE ONLINE
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Mailbox - Basic diagnostics" -Cat "Exchange" -Sub "Mailbox" `
        -Desc "Retrieve mailbox type, size, quotas and litigation hold status." `
        -PSV "5 & 7" -Tags "exchange, mailbox, quota, size, hold" `
        -Notes "RecipientTypeDetails identifies shared, room, equipment or user mailboxes." `
        -Scr @'
Connect-ExchangeOnline -UserPrincipalName '<AdminEmail>'

# Mailbox properties
Get-Mailbox -Identity '<UserEmail>' |
    Select-Object DisplayName, RecipientTypeDetails, PrimarySmtpAddress, LitigationHoldEnabled, RetentionPolicy

# Mailbox size and item count
Get-MailboxStatistics -Identity '<UserEmail>' |
    Select-Object DisplayName, TotalItemSize, ItemCount, LastLogonTime

# Archive mailbox status
Get-Mailbox -Identity '<UserEmail>' | Select-Object ArchiveStatus, ArchiveQuota, AutoExpandingArchiveEnabled
'@

    $d += New-CmdEntry -N "Mailbox permissions (Full Access / SendAs)" -Cat "Exchange" -Sub "Permissions" `
        -Desc "Grant, list and remove Full Access and Send As permissions on a mailbox." `
        -PSV "5 & 7" -Tags "exchange, permissions, full access, send as, delegate" `
        -Notes "Use AutoMapping false to avoid the mailbox being auto-added in Outlook." `
        -Scr @'
# List current permissions
Get-MailboxPermission -Identity '<UserEmail>' | Where-Object { $_.User -notlike 'NT AUTHORITY*' }
Get-RecipientPermission -Identity '<UserEmail>'

# Grant Full Access
Add-MailboxPermission -Identity '<UserEmail>' -User '<DelegateEmail>' `
    -AccessRights FullAccess -InheritanceType All -AutoMapping $false

# Grant Send As
Add-RecipientPermission -Identity '<UserEmail>' -Trustee '<DelegateEmail>' -AccessRights SendAs -Confirm:$false

# Remove Full Access
Remove-MailboxPermission -Identity '<UserEmail>' -User '<DelegateEmail>' -AccessRights FullAccess -Confirm:$false
'@

    $d += New-CmdEntry -N "Message Trace" -Cat "Exchange" -Sub "Troubleshooting" `
        -Desc "Trace sent and received messages to troubleshoot mail flow and delivery issues." `
        -PSV "5 & 7" -Tags "exchange, message trace, mail flow, delivery, troubleshooting" `
        -Notes "Get-MessageTrace covers the last 10 days. Use Start-HistoricalSearch for older data." `
        -Scr @'
# Last 48 hours for a sender
Get-MessageTrace -SenderAddress '<SenderEmail>' `
    -StartDate (Get-Date).AddDays(-2) -EndDate (Get-Date) |
    Select-Object Received, SenderAddress, RecipientAddress, Subject, Status

# Detail of a specific message
Get-MessageTraceDetail -MessageTraceId '<MessageTraceId>' -RecipientAddress '<RecipientEmail>'

# Historical search (up to 90 days, delivered by report)
Start-HistoricalSearch -ReportTitle 'Case <CaseNumber>' `
    -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) `
    -ReportType MessageTrace -SenderAddress '<SenderEmail>' -NotifyAddress '<AdminEmail>'
'@

    $d += New-CmdEntry -N "M365 Group - Inspect and update" -Cat "Exchange" -Sub "M365 Groups" `
        -Desc "Inspect a Microsoft 365 group, its members/owners and its linked SharePoint site." `
        -PSV "5 & 7" -Tags "exchange, M365 group, unified group, owners, members, teams site" `
        -Notes "Each M365 group provisions a SharePoint team site; group membership drives site access." `
        -Scr @'
# Group properties
Get-UnifiedGroup -Identity '<GroupName>' |
    Format-List DisplayName, PrimarySmtpAddress, SharePointSiteUrl, AccessType, ExternalMemberCount

# Members and owners
Get-UnifiedGroupLinks -Identity '<GroupName>' -LinkType Members
Get-UnifiedGroupLinks -Identity '<GroupName>' -LinkType Owners

# Add an owner (must also be a member)
Add-UnifiedGroupLinks -Identity '<GroupName>' -LinkType Members -Links '<UserEmail>'
Add-UnifiedGroupLinks -Identity '<GroupName>' -LinkType Owners  -Links '<UserEmail>'

# Hide the group from the GAL
Set-UnifiedGroup -Identity '<GroupName>' -HiddenFromAddressListsEnabled $true
'@

    # ------------------------------------------------------------------
    # TEAMS
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Teams - Inspect team, channels and members" -Cat "Teams" -Sub "Query" `
        -Desc "List teams, channels, owners and members, including the underlying SharePoint site." `
        -PSV "5 & 7" -Tags "teams, channels, members, owners, groupid" `
        -Notes "Every team has a GroupId; the files tab points to the linked SharePoint site." `
        -Scr @'
Connect-MicrosoftTeams

# Find a team and get its GroupId
Get-Team -DisplayName '<TeamName>' | Select-Object GroupId, DisplayName, Visibility, Archived

# Channels of the team (Standard, Private, Shared)
Get-TeamChannel -GroupId '<GroupId>' | Select-Object DisplayName, MembershipType, Description

# Members and owners
Get-TeamUser -GroupId '<GroupId>' | Select-Object User, Name, Role

# Private/Shared channel members
Get-TeamChannelUser -GroupId '<GroupId>' -DisplayName '<ChannelName>'

# Linked SharePoint site
Get-UnifiedGroup -Identity '<GroupId>' | Select-Object DisplayName, SharePointSiteUrl
'@

    $d += New-CmdEntry -N "Teams - Manage membership and archive" -Cat "Teams" -Sub "Administration" `
        -Desc "Add or remove team members/owners and archive or restore a team." `
        -PSV "5 & 7" -Tags "teams, add member, owner, archive, restore" `
        -Notes "Archiving a team sets the team and its SharePoint site to read-only." `
        -Scr @'
# Add member / owner
Add-TeamUser -GroupId '<GroupId>' -User '<UserEmail>'
Add-TeamUser -GroupId '<GroupId>' -User '<UserEmail>' -Role Owner

# Remove member
Remove-TeamUser -GroupId '<GroupId>' -User '<UserEmail>'

# Archive team (also sets the SPO site read-only)
Set-TeamArchivedState -GroupId '<GroupId>' -Archived $true -SetSpoSiteReadOnlyForMembers $true

# Restore team
Set-TeamArchivedState -GroupId '<GroupId>' -Archived $false
'@

    $d += New-CmdEntry -N "Teams - Policies assigned to a user" -Cat "Teams" -Sub "Policies" `
        -Desc "Review and assign Teams policies (meeting, messaging, apps) for a user." `
        -PSV "5 & 7" -Tags "teams, policy, meeting, messaging, app permission" `
        -Notes "Policy assignment can take a few hours to be effective for the end user." `
        -Scr @'
# Effective policies for a user
Get-CsUserPolicyAssignment -Identity '<UserEmail>' | Format-Table PolicyType, PolicyName

# List available policies
Get-CsTeamsMeetingPolicy   | Select-Object Identity
Get-CsTeamsMessagingPolicy | Select-Object Identity
Get-CsTeamsAppPermissionPolicy | Select-Object Identity

# Assign a policy
Grant-CsTeamsMeetingPolicy   -Identity '<UserEmail>' -PolicyName '<PolicyName>'
Grant-CsTeamsMessagingPolicy -Identity '<UserEmail>' -PolicyName '<PolicyName>'
'@

    # ------------------------------------------------------------------
    # ENTRA ID
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Entra ID - User diagnostics" -Cat "Entra ID" -Sub "Users" `
        -Desc "Retrieve user account details, licenses and sign-in blocked status via Graph." `
        -PSV "7" -Tags "entra, user, license, graph, account enabled" `
        -Notes "A disabled or unlicensed account is a very common root cause for access issues." `
        -Scr @'
Connect-MgGraph -Scopes 'User.Read.All','Directory.Read.All'

# Core user properties
Get-MgUser -UserId '<UserEmail>' -Property Id,DisplayName,UserPrincipalName,AccountEnabled,UserType,OnPremisesSyncEnabled,CreatedDateTime |
    Select-Object DisplayName, UserPrincipalName, AccountEnabled, UserType, OnPremisesSyncEnabled, CreatedDateTime

# Assigned licenses
Get-MgUserLicenseDetail -UserId '<UserEmail>' | Select-Object SkuPartNumber, ServicePlans

# Group memberships
Get-MgUserMemberOf -UserId '<UserEmail>' |
    ForEach-Object { $_.AdditionalProperties.displayName }

# Guest users in the tenant
Get-MgUser -Filter "userType eq 'Guest'" -All | Select-Object DisplayName, UserPrincipalName, CreatedDateTime
'@

    $d += New-CmdEntry -N "Entra ID - Sign-in logs and audit" -Cat "Entra ID" -Sub "Troubleshooting" `
        -Desc "Query sign-in logs and directory audit events for a user." `
        -PSV "7" -Tags "entra, sign-in, audit, conditional access, logs" `
        -Notes "Sign-in logs require an Entra ID P1/P2 license. Retention is 30 days." `
        -Scr @'
Connect-MgGraph -Scopes 'AuditLog.Read.All','Directory.Read.All'

# Recent sign-ins for a user
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '<UserEmail>'" -Top 25 |
    Select-Object CreatedDateTime, AppDisplayName, IpAddress,
        @{N='Status';E={$_.Status.ErrorCode}},
        @{N='Reason';E={$_.Status.FailureReason}}

# Failed sign-ins only
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '<UserEmail>' and status/errorCode ne 0" -Top 25 |
    Select-Object CreatedDateTime, AppDisplayName, @{N='Error';E={$_.Status.ErrorCode}}

# Directory audit events
Get-MgAuditLogDirectoryAudit -Filter "initiatedBy/user/userPrincipalName eq '<UserEmail>'" -Top 25 |
    Select-Object ActivityDateTime, ActivityDisplayName, Result
'@

    $d += New-CmdEntry -N "Entra ID - Groups and app registrations" -Cat "Entra ID" -Sub "Directory" `
        -Desc "Inspect security groups, memberships, app registrations and service principals." `
        -PSV "7" -Tags "entra, group, app registration, service principal, secret" `
        -Notes "Expired client secrets or certificates are a frequent cause of failing automations." `
        -Scr @'
Connect-MgGraph -Scopes 'Group.Read.All','Application.Read.All'

# Group and its members
Get-MgGroup -Filter "displayName eq '<GroupName>'" |
    Select-Object Id, DisplayName, GroupTypes, SecurityEnabled, MailEnabled
Get-MgGroupMember -GroupId '<GroupId>' -All | ForEach-Object { $_.AdditionalProperties.userPrincipalName }

# App registration and credential expiration
$app = Get-MgApplication -Filter "displayName eq '<AppName>'"
$app | Select-Object DisplayName, AppId, Id
$app.PasswordCredentials | Select-Object DisplayName, StartDateTime, EndDateTime
$app.KeyCredentials      | Select-Object DisplayName, StartDateTime, EndDateTime

# Service principal permissions granted
Get-MgServicePrincipal -Filter "appId eq '<AppId>'" | Select-Object Id, DisplayName, AppRoles
'@

    # ------------------------------------------------------------------
    # AZURE
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Azure - Subscriptions and resources" -Cat "Azure" -Sub "Query" `
        -Desc "List subscriptions, resource groups and resources; switch active context." `
        -PSV "7" -Tags "azure, subscription, resource group, resources, context" `
        -Notes "Always confirm the active context before running write operations." `
        -Scr @'
Connect-AzAccount

# Subscriptions and active context
Get-AzSubscription | Select-Object Name, Id, State
Set-AzContext -SubscriptionId '<SubscriptionId>'
Get-AzContext | Select-Object Name, Account, Subscription, Tenant

# Resource groups and resources
Get-AzResourceGroup | Select-Object ResourceGroupName, Location
Get-AzResource -ResourceGroupName '<ResourceGroupName>' | Select-Object Name, ResourceType, Location
'@

    $d += New-CmdEntry -N "Azure - RBAC role assignments" -Cat "Azure" -Sub "Permissions" `
        -Desc "Review, grant and remove Azure RBAC role assignments." `
        -PSV "7" -Tags "azure, rbac, role assignment, permissions, scope" `
        -Notes "Scope inherits downward: management group, subscription, resource group, resource." `
        -Scr @'
# Current assignments for a user
Get-AzRoleAssignment -SignInName '<UserEmail>' |
    Select-Object DisplayName, RoleDefinitionName, Scope

# Assignments at resource group scope
Get-AzRoleAssignment -ResourceGroupName '<ResourceGroupName>' |
    Select-Object DisplayName, RoleDefinitionName, Scope

# Grant a role
New-AzRoleAssignment -SignInName '<UserEmail>' `
    -RoleDefinitionName 'Reader' `
    -ResourceGroupName '<ResourceGroupName>'

# Remove a role
Remove-AzRoleAssignment -SignInName '<UserEmail>' `
    -RoleDefinitionName 'Reader' `
    -ResourceGroupName '<ResourceGroupName>'
'@

    $d += New-CmdEntry -N "Azure - Storage account and blob access" -Cat "Azure" -Sub "Storage" `
        -Desc "Inspect a storage account, list containers and generate a temporary SAS token." `
        -PSV "7" -Tags "azure, storage, blob, container, SAS" `
        -Notes "Prefer short-lived, read-only SAS tokens when sharing diagnostic files." `
        -Scr @'
# Storage account context
$ctx = (Get-AzStorageAccount -ResourceGroupName '<ResourceGroupName>' -Name '<StorageAccountName>').Context

# Containers and blobs
Get-AzStorageContainer -Context $ctx | Select-Object Name, LastModified
Get-AzStorageBlob -Container '<ContainerName>' -Context $ctx | Select-Object Name, Length, LastModified

# Read-only SAS token valid for 24 hours
New-AzStorageContainerSASToken -Name '<ContainerName>' -Context $ctx `
    -Permission r -ExpiryTime (Get-Date).AddHours(24) -FullUri
'@

    # ------------------------------------------------------------------
    # PURVIEW / COMPLIANCE
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Unified Audit Log search" -Cat "Purview" -Sub "Audit" `
        -Desc "Search the unified audit log for file, sharing and deletion activity." `
        -PSV "5 & 7" -Tags "purview, audit, compliance, deleted, sharing, log" `
        -Notes "Audit retention depends on licensing (E3 180 days, E5 365 days)." `
        -Scr @'
Connect-ExchangeOnline -UserPrincipalName '<AdminEmail>'

# File deletion activity on a site
Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) `
    -RecordType SharePointFileOperation `
    -Operations FileDeleted,FileDeletedFirstStageRecycleBin,FileDeletedSecondStageRecycleBin `
    -ObjectIds 'https://<TenantName>.sharepoint.com/sites/<SiteName>*' `
    -ResultSize 5000 |
    Select-Object CreationDate, UserIds, Operations, AuditData

# Sharing activity by a user
Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) `
    -UserIds '<UserEmail>' `
    -Operations SharingSet,SharingInvitationCreated,AnonymousLinkCreated `
    -ResultSize 1000

# Expand the AuditData JSON payload
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -UserIds '<UserEmail>' -ResultSize 100 |
    ForEach-Object { $_.AuditData | ConvertFrom-Json } |
    Select-Object CreationTime, Operation, ObjectId, ClientIP
'@

    # ------------------------------------------------------------------
    # TROUBLESHOOTING
    # ------------------------------------------------------------------
    $d += New-CmdEntry -N "Site Health Check" -Cat "Troubleshooting" -Sub "Diagnostics" `
        -Desc "Commands to verify the status and health of a SharePoint site." `
        -PSV "5 & 7" -Tags "status, diagnostics, health, lock, troubleshooting" `
        -Notes "LockState: Unlock normal, ReadOnly read-only, NoAccess blocked." `
        -Scr @'
# Check if site exists and its status
Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' |
    Select-Object Url, Status, LockState, DenyAddAndCustomizePages

# Check if site is in ReadOnly mode
$site = Get-SPOSite -Identity 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Detailed
$site.LockState

# PnP connection test
Connect-PnPOnline -Url 'https://<TenantName>.sharepoint.com/sites/<SiteName>' -Interactive -ClientId '<AppId>'
Get-PnPWeb | Select-Object Title, Url, LastItemModifiedDate
'@

    $d += New-CmdEntry -N "PITR - Point In Time Restore" -Cat "Troubleshooting" -Sub "Restore" `
        -Desc "Information required to request a Point In Time Restore for an SPO site." `
        -PSV "N/A" -Tags "PITR, restore, backup, point in time, backend" `
        -Notes "PITR covers a maximum of 14 days and is requested via escalation to the backend team." `
        -Scr @'
# PITR is requested to the backend team via IcM / escalation

# Self-service restore (limited):
# Admin Center > Active Sites > Select site > Restore

# Information required to request PITR from backend:
# 1. Site URL
# 2. Exact restore date/time (UTC)
# 3. Business justification
# 4. Tenant ID
# 5. Tenant admin confirmation
'@

    $d += New-CmdEntry -N "HAR File - Capture instructions" -Cat "Troubleshooting" -Sub "Diagnostics" `
        -Desc "Instructions to request a HAR capture from the customer and how to analyze it." `
        -PSV "N/A" -Tags "HAR, network, troubleshooting, browser, diagnostics" `
        -Notes "HAR files may contain tokens. Handle them as sensitive data." `
        -Scr @'
# === INSTRUCTIONS FOR THE CUSTOMER ===
# 1. Open the browser (Edge/Chrome)
# 2. Press F12 to open DevTools
# 3. Go to the 'Network' tab
# 4. Check the 'Preserve log' checkbox
# 5. Reproduce the issue
# 6. Right-click on the request list
# 7. Select 'Save all as HAR with content'
# 8. Send the .har file

# === TO ANALYZE ===
# - Open in DevTools > Network > Import HAR
# - Look for requests with status 400, 403, 404, 500
# - Check authentication headers
# - Verify response times
'@

    return $d
}
