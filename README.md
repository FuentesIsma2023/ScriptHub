# ScriptHub

Community Toolkit for Support Engineers.

ScriptHub 4.0 is an offline-first PowerShell application (WinForms) that searches, parameterizes and runs curated scripts for Microsoft 365 workloads: SharePoint Online, OneDrive, Exchange Online, Microsoft Graph, Entra ID, Teams and Azure.

## Why

Support engineers rebuild the same commands on every case. Scripts live scattered across chats, notes and personal folders, with no shared, searchable and validated place to reuse them.

## Features

- Full-text search across name, description, script body, tags, category and notes
- Filters by category and PowerShell version
- Filters by workload team
- Shows detected module dependencies and installed versions
- Installs missing modules for the selected script
- Links to PowerShell 7 when a script requires it
- Automatic placeholder detection with a generated parameter form
- Editable script preview before execution
- Run in a separate PowerShell session
- Export any script as a standalone .ps1 file
- Copy to clipboard
- Catalog validation for incomplete or duplicate entries
- Explicit confirmation before executing an editable script
- Opens each script with the PowerShell version declared by the catalog

## Requirements

- Windows PowerShell 5.1 or PowerShell 7
- Windows (WinForms)

## Usage

```powershell
cd C:\Path\To\ScriptHub
Set-ExecutionPolicy RemoteSigned -Scope Process
.\ScriptHub.UI.ps1
```

The recommended launcher is:

```text
Launch-ScriptHub.bat
```

`ScriptHub.UI.ps1` is the current entry point. `ScriptHub.Core.ps1` and
`ScriptHub.Catalog.ps1` are loaded automatically and should not be run alone.

Before using the Site, Feedback or Suggest Script buttons, replace the example
URLs in `ScriptHub.Core.ps1` with the real SharePoint pages.
