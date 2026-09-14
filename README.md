# ScriptHub

Community Toolkit for Support Engineers.

ScriptHub is an offline-first PowerShell application (WinForms) that stores, searches, parameterizes and runs curated scripts for Microsoft 365 workloads: SharePoint Online, OneDrive, Exchange Online, Microsoft Graph and Entra ID.

## Why

Support engineers rebuild the same commands on every case. Scripts live scattered across chats, notes and personal folders, with no shared, searchable and validated place to reuse them.

## Features

- Full-text search across name, description, script body, tags, category and notes
- Filters by category and PowerShell version
- Automatic placeholder detection with a generated parameter form
- Editable script preview before execution
- Run in a separate PowerShell session
- Export any script as a standalone .ps1 file
- Copy to clipboard
- CSV import and export for sharing libraries
- Local persistence in the user profile

## Requirements

- Windows PowerShell 5.1 or PowerShell 7
- Windows (WinForms)

## Usage

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\ScriptHub.ps1
