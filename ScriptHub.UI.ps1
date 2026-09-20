# ============================================================================
# ScriptHub.UI.ps1 - Presentation layer (WinForms) and application entry point
# RUN THIS FILE to launch ScriptHub.
#
# Required files in the same folder:
#   ScriptHub.Core.ps1     -> logic
#   ScriptHub.Catalog.ps1  -> script listing
#
# Author: Ismael Najera
# Collaborator: Diego Saldivar
# ============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ScriptHubNative
{
    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);
}

public sealed class ScriptHubResizeWindow : System.Windows.Forms.NativeWindow, System.IDisposable
{
    private const int WM_NCHITTEST = 0x84;
    private const int WM_GETMINMAXINFO = 0x24;
    private const int HTCLIENT = 1;
    private const int HTLEFT = 10;
    private const int HTRIGHT = 11;
    private const int HTTOP = 12;
    private const int HTTOPLEFT = 13;
    private const int HTTOPRIGHT = 14;
    private const int HTBOTTOM = 15;
    private const int HTBOTTOMLEFT = 16;
    private const int HTBOTTOMRIGHT = 17;
    private const int BORDER_SIZE = 8;

    public ScriptHubResizeWindow(System.Windows.Forms.Form form)
    {
        AssignHandle(form.Handle);
    }

    protected override void WndProc(ref System.Windows.Forms.Message message)
    {
        if (message.Msg == WM_NCHITTEST && !IsMaximized())
        {
            int x = (short)((long)message.LParam & 0xFFFF);
            int y = (short)(((long)message.LParam >> 16) & 0xFFFF);
            System.Drawing.Point point = TargetForm.PointToClient(new System.Drawing.Point(x, y));
            int width = TargetForm.ClientSize.Width;
            int height = TargetForm.ClientSize.Height;
            bool left = point.X <= BORDER_SIZE;
            bool right = point.X >= width - BORDER_SIZE;
            bool top = point.Y <= BORDER_SIZE;
            bool bottom = point.Y >= height - BORDER_SIZE;

            if (left && top) message.Result = (IntPtr)HTTOPLEFT;
            else if (right && top) message.Result = (IntPtr)HTTOPRIGHT;
            else if (left && bottom) message.Result = (IntPtr)HTBOTTOMLEFT;
            else if (right && bottom) message.Result = (IntPtr)HTBOTTOMRIGHT;
            else if (left) message.Result = (IntPtr)HTLEFT;
            else if (right) message.Result = (IntPtr)HTRIGHT;
            else if (top) message.Result = (IntPtr)HTTOP;
            else if (bottom) message.Result = (IntPtr)HTBOTTOM;
            else message.Result = (IntPtr)HTCLIENT;

            if ((int)message.Result != HTCLIENT) return;
        }

        base.WndProc(ref message);
    }

    private System.Windows.Forms.Form TargetForm
    {
        get { return System.Windows.Forms.Control.FromHandle(Handle) as System.Windows.Forms.Form; }
    }

    private bool IsMaximized()
    {
        System.Windows.Forms.Form form = TargetForm;
        return form != null && form.WindowState == System.Windows.Forms.FormWindowState.Maximized;
    }

    public void Dispose()
    {
        ReleaseHandle();
    }
}
'@ -ReferencedAssemblies 'System.Windows.Forms.dll', 'System.Drawing.dll'

# === LOAD DEPENDENCIES ===
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
foreach ($dep in @('ScriptHub.Core.ps1', 'ScriptHub.Catalog.ps1')) {
    $depPath = Join-Path $here $dep
    if (-not (Test-Path $depPath)) {
        [System.Windows.Forms.MessageBox]::Show("Missing file: $dep`nIt must be in the same folder as ScriptHub.UI.ps1.", "ScriptHub", "OK", "Error")
        return
    }
    . $depPath
}

# === MODERN WINDOWS 11 STYLE CONSTANTS ===
$script:C_Gray     = [System.Drawing.Color]::FromArgb(243,246,250)
$script:C_DarkGray = [System.Drawing.Color]::FromArgb(96,103,112)
$script:C_White    = [System.Drawing.Color]::White
$script:C_Navy     = [System.Drawing.Color]::FromArgb(0,103,192)
$script:C_TitleBar = [System.Drawing.Color]::FromArgb(18,18,18)
$script:C_TitleBarAlt = [System.Drawing.Color]::FromArgb(32,32,32)
$script:C_TermBG   = [System.Drawing.Color]::FromArgb(27,31,38)
$script:C_TermFG   = [System.Drawing.Color]::FromArgb(232,236,241)
$script:C_DarkRed  = [System.Drawing.Color]::FromArgb(196,61,61)
$script:C_Border   = [System.Drawing.Color]::FromArgb(220,225,232)
$script:C_Accent   = [System.Drawing.Color]::FromArgb(0,120,212)
$script:C_AccentHover = [System.Drawing.Color]::FromArgb(0,100,190)
$script:C_AccentPressed = [System.Drawing.Color]::FromArgb(0,88,170)
$script:C_Surface  = [System.Drawing.Color]::FromArgb(250,250,250)
$script:C_SurfaceAlt = [System.Drawing.Color]::FromArgb(244,246,249)
$script:C_TextPrimary = [System.Drawing.Color]::FromArgb(28,28,28)
$script:C_TextSecondary = [System.Drawing.Color]::FromArgb(96,103,112)

$script:StyleBold  = [System.Drawing.FontStyle]::Bold
$script:FNormal    = New-Object System.Drawing.Font("Segoe UI",9)
$script:FBold      = New-Object System.Drawing.Font("Segoe UI",9,$script:StyleBold)
$script:FMono      = New-Object System.Drawing.Font("Consolas",9)
$script:FTitle     = New-Object System.Drawing.Font("Segoe UI",10,$script:StyleBold)

function Set-RoundedCorners {
    param(
        [System.Windows.Forms.Control]$Control,
        [int]$Radius = 10
    )
    if ($Control -eq $null) { return }
    if ($Control.Width -le 0 -or $Control.Height -le 0) { return }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2
    $path.AddArc(0, 0, $diameter, $diameter, 180, 90)
    $path.AddArc($Control.Width - $diameter, 0, $diameter, $diameter, 270, 90)
    $path.AddArc($Control.Width - $diameter, $Control.Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc(0, $Control.Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    $oldRegion = $Control.Region
    $Control.Region = New-Object System.Drawing.Region($path)
    if ($oldRegion) { $oldRegion.Dispose() }
    $path.Dispose()
}

function New-W95Btn {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=90,[int]$H=28)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Location = New-Object System.Drawing.Point($X,$Y)
    $b.Size = New-Object System.Drawing.Size($W,$H)
    $b.Font = $script:FNormal
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 0
    $b.FlatAppearance.BorderColor = $script:C_Border
    $b.UseVisualStyleBackColor = $false
    $b.BackColor = $script:C_White
    $b.ForeColor = $script:C_TextPrimary
    $b.Padding = New-Object System.Windows.Forms.Padding(6,0,6,0)
    $b.Margin = New-Object System.Windows.Forms.Padding(0)
    $b.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    Set-RoundedCorners -Control $b -Radius 8
    $b.Add_Resize({ Set-RoundedCorners -Control $this -Radius 8 })
    return $b
}

function New-TitleBarButton {
    param(
        [string]$Text,
        [string]$Action,
        [int]$Width = 46,
        [int]$Height = 32
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Size = New-Object System.Drawing.Size($Width, $Height)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.BackColor = [System.Drawing.Color]::Transparent
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Tag = $Action
    $btn.Add_MouseEnter({
        if ($this.Tag -eq 'close') { $this.BackColor = [System.Drawing.Color]::FromArgb(232,17,35) }
        else { $this.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255) } 
        $this.ForeColor = [System.Drawing.Color]::White
    })
    $btn.Add_MouseLeave({
        $this.BackColor = [System.Drawing.Color]::Transparent
        $this.ForeColor = [System.Drawing.Color]::White
    })
    return $btn
}

# === HELPER: Win95 label ===
function New-W95Lbl {
    param([string]$Text,[int]$X,[int]$Y,[int]$W=200,[int]$H=16,[switch]$Bold)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.Location = New-Object System.Drawing.Point($X,$Y)
    $l.Size = New-Object System.Drawing.Size($W,$H)
    $l.Font = $(if ($Bold) { $script:FBold } else { $script:FNormal })
    $l.BackColor = [System.Drawing.Color]::Transparent
    return $l
}

# ============================================================================
# SHOW-RUNFORM: Parameter detection + execution UI
# ============================================================================
function Show-RunForm {
    param(
        [string]$ScriptText,
        [string]$CmdName,
        [string]$PSVersion = '5 & 7'
    )

    $phList    = Get-ScriptHubPlaceholder -ScriptText $ScriptText
    $hasParams = $phList.Count -gt 0

    $paramHeight = 0
    if ($hasParams) {
        $calc = ($phList.Count * 30) + 60
        if ($calc -gt 300) { $calc = 300 }
        $paramHeight = $calc
    }
    $formH = 550 + $paramHeight

    $rf = New-Object System.Windows.Forms.Form
    $rf.Text = "Run: $CmdName"
    $rf.Size = New-Object System.Drawing.Size(880, $formH)
    $rf.StartPosition = "CenterParent"
    $rf.BackColor = $script:C_Gray
    $rf.Font = $script:FNormal
    $rf.MinimumSize = New-Object System.Drawing.Size(700, 450)

    $y = 8
    $inputFields = @{}

    # --- Parameters section ---
    if ($hasParams) {
        $grpParams = New-Object System.Windows.Forms.GroupBox
        $grpParams.Text = " Parameters detected - fill in values "
        $grpParams.Font = $script:FBold
        $grpParams.Location = New-Object System.Drawing.Point(8, $y)
        $grpParams.Size = New-Object System.Drawing.Size(848, ($paramHeight - 10))
        $grpParams.BackColor = $script:C_Gray
        $rf.Controls.Add($grpParams)

        $pnlScroll = New-Object System.Windows.Forms.Panel
        $pnlScroll.Location = New-Object System.Drawing.Point(6, 18)
        $pnlScroll.Size = New-Object System.Drawing.Size(836, ($paramHeight - 34))
        $pnlScroll.AutoScroll = $true
        $pnlScroll.BackColor = $script:C_Gray
        $grpParams.Controls.Add($pnlScroll)

        $py = 2
        foreach ($ph in $phList) {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = "${ph}:"
            $lbl.Location = New-Object System.Drawing.Point(6, ($py + 3))
            $lbl.Size = New-Object System.Drawing.Size(180, 18)
            $lbl.Font = $script:FNormal
            $pnlScroll.Controls.Add($lbl)

            $txt = New-Object System.Windows.Forms.TextBox
            $txt.Location = New-Object System.Drawing.Point(192, $py)
            $txt.Size = New-Object System.Drawing.Size(610, 22)
            $txt.Font = $script:FNormal
            $pnlScroll.Controls.Add($txt)

            $inputFields[$ph] = $txt
            $py += 28
        }
        $y += $paramHeight - 5
    }

    # --- Button bar ---
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

    $arrow = [string][char]9654
    $btnRunPS = New-W95Btn -Text ($arrow + " Open in PowerShell") -X $bx -Y 2 -W 170 -H 28
    $btnRunPS.Font = $script:FBold
    $btnRunPS.BackColor = $script:C_Accent
    $btnRunPS.ForeColor = $script:C_White
    $btnRunPS.FlatAppearance.BorderColor = $script:C_Accent
    $btnRunPS.FlatAppearance.MouseOverBackColor = $script:C_AccentHover
    $pnlBtns.Controls.Add($btnRunPS)
    $bx += 180

    $btnCopyR = New-W95Btn -Text "Copy to Clipboard" -X $bx -Y 2 -W 140 -H 28
    $pnlBtns.Controls.Add($btnCopyR)

    $btnCloseR = New-W95Btn -Text "Close" -X 758 -Y 2 -W 90 -H 28
    $pnlBtns.Controls.Add($btnCloseR)

    $y += 38

    $lblPrev = New-W95Lbl -Text "Script preview (editable before running):" -X 8 -Y $y -W 400 -Bold
    $rf.Controls.Add($lblPrev)
    $y += 18

    $txtPrev = New-Object System.Windows.Forms.RichTextBox
    $txtPrev.Location = New-Object System.Drawing.Point(8, $y)
    $txtPrev.Font = $script:FMono
    $txtPrev.BackColor = $script:C_TermBG
    $txtPrev.ForeColor = $script:C_TermFG
    $txtPrev.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $txtPrev.WordWrap = $false
    $txtPrev.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Both
    $txtPrev.Text = $ScriptText

    $anchorAll = [System.Windows.Forms.AnchorStyles]::Top
    $anchorAll = $anchorAll -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $anchorAll = $anchorAll -bor [System.Windows.Forms.AnchorStyles]::Left
    $anchorAll = $anchorAll -bor [System.Windows.Forms.AnchorStyles]::Right
    $txtPrev.Anchor = $anchorAll

    $txtPrev.Size = New-Object System.Drawing.Size(848, ($formH - $y - 80))
    $rf.Controls.Add($txtPrev)

    # --- Events ---
    if ($hasParams) {
        $btnApply.Add_Click({
            $values = @{}
            foreach ($ph in $phList) { $values[$ph] = $inputFields[$ph].Text }
            $txtPrev.Text = Expand-ScriptHubPlaceholder -ScriptText $ScriptText -Values $values
        }.GetNewClosure())
    }

    $btnRunPS.Add_Click({
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "This will execute the editable script in a new PowerShell window. Continue?",
            "Confirm execution",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        try {
            [void](Invoke-ScriptHubScript -ScriptText $txtPrev.Text -CmdName $CmdName -PSVersion $PSVersion)
        } catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Execution error", "OK", "Error")
        }
    }.GetNewClosure())

    $btnCopyR.Add_Click({
        if ($txtPrev.Text -ne "") {
            [System.Windows.Forms.Clipboard]::SetText($txtPrev.Text)
            [System.Windows.Forms.MessageBox]::Show("Script copied to clipboard.","Done","OK","Information")
        }
    }.GetNewClosure())

    $btnCloseR.Add_Click({ $rf.Close() })
    $rf.CancelButton = $btnCloseR

    Set-RoundedCorners -Control $rf -Radius 12
    $rf.Add_Resize({ Set-RoundedCorners -Control $this -Radius 12 })
    [void]$rf.ShowDialog()
    $rf.Dispose()
}

# ============================================================================
# SHOW-SUBMITFORM: Script suggestion / intake helper
# The catalog is code-owned, so nothing is written here. The form collects the
# proposal, opens the request form on the ScriptHub site and generates the
# catalog block the reviewer pastes into ScriptHub.Catalog.ps1 once approved.
# ============================================================================
function Show-SubmitForm {

    $sf = New-Object System.Windows.Forms.Form
    $sf.Text = "Suggest a script"
    $sf.Size = New-Object System.Drawing.Size(650, 620)
    $sf.StartPosition = "CenterParent"
    $sf.BackColor = $script:C_Gray
    $sf.Font = $script:FNormal
    $sf.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $sf.MaximizeBox = $false
    $sf.MinimizeBox = $false

    $sf.Controls.Add((New-W95Lbl -Text "Fill in the proposal, then submit it through the request form on the ScriptHub site." -X 8 -Y 10 -W 600 -Bold))

    $y = 34
    $lW = 90
    $cX = 105
    $cW = 505

    $sf.Controls.Add((New-W95Lbl -Text "Name:" -X 8 -Y $y -W $lW -Bold))
    $tN = New-Object System.Windows.Forms.TextBox
    $tN.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tN.Size = New-Object System.Drawing.Size($cW, 22)
    $tN.Font = $script:FNormal
    $sf.Controls.Add($tN)
    $y += 28

    $sf.Controls.Add((New-W95Lbl -Text "Category:" -X 8 -Y $y -W $lW -Bold))
    $tCat = New-Object System.Windows.Forms.ComboBox
    $tCat.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tCat.Size = New-Object System.Drawing.Size(190, 22)
    $tCat.Font = $script:FNormal
    $tCat.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $catList = @("Modules","Connection","PnP Registration","Site Management","Permissions","Recycle Bin","Files","OneDrive","Tenant","Sharing","Exchange","Teams","Entra ID","Azure","Purview","Troubleshooting","Other")
    foreach ($c in $catList) { [void]$tCat.Items.Add($c) }
    $sf.Controls.Add($tCat)

    $sf.Controls.Add((New-W95Lbl -Text "SubCat:" -X 315 -Y $y -W 55))
    $tSub = New-Object System.Windows.Forms.TextBox
    $tSub.Location = New-Object System.Drawing.Point(375, ($y-2))
    $tSub.Size = New-Object System.Drawing.Size(235, 22)
    $tSub.Font = $script:FNormal
    $sf.Controls.Add($tSub)
    $y += 28

    $sf.Controls.Add((New-W95Lbl -Text "PS Version:" -X 8 -Y $y -W $lW -Bold))
    $tPSV = New-Object System.Windows.Forms.ComboBox
    $tPSV.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tPSV.Size = New-Object System.Drawing.Size(140, 22)
    $tPSV.Font = $script:FNormal
    $tPSV.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $tPSV.Items.AddRange(@("5","7","5 & 7","7 (recommended)","N/A"))
    $tPSV.SelectedIndex = 2
    $sf.Controls.Add($tPSV)
    $y += 28

    $sf.Controls.Add((New-W95Lbl -Text "Description:" -X 8 -Y $y -W $lW -Bold))
    $tDesc = New-Object System.Windows.Forms.TextBox
    $tDesc.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tDesc.Size = New-Object System.Drawing.Size($cW, 44)
    $tDesc.Font = $script:FNormal
    $tDesc.Multiline = $true
    $sf.Controls.Add($tDesc)
    $y += 52

    $sf.Controls.Add((New-W95Lbl -Text "Script:" -X 8 -Y $y -W $lW -Bold))
    $tScr = New-Object System.Windows.Forms.TextBox
    $tScr.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tScr.Size = New-Object System.Drawing.Size($cW, 200)
    $tScr.Font = $script:FMono
    $tScr.Multiline = $true
    $tScr.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    $tScr.WordWrap = $false
    $tScr.AcceptsTab = $true
    $tScr.BackColor = $script:C_TermBG
    $tScr.ForeColor = $script:C_TermFG
    $sf.Controls.Add($tScr)
    $y += 208

    $sf.Controls.Add((New-W95Lbl -Text "Tags:" -X 8 -Y $y -W $lW -Bold))
    $tTags = New-Object System.Windows.Forms.TextBox
    $tTags.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tTags.Size = New-Object System.Drawing.Size($cW, 22)
    $tTags.Font = $script:FNormal
    $sf.Controls.Add($tTags)
    $y += 28

    $sf.Controls.Add((New-W95Lbl -Text "Notes:" -X 8 -Y $y -W $lW -Bold))
    $tNotes = New-Object System.Windows.Forms.TextBox
    $tNotes.Location = New-Object System.Drawing.Point($cX, ($y-2))
    $tNotes.Size = New-Object System.Drawing.Size($cW, 40)
    $tNotes.Font = $script:FNormal
    $tNotes.Multiline = $true
    $sf.Controls.Add($tNotes)
    $y += 50

    $bForm = New-W95Btn -Text "Open request form" -X 8 -Y $y -W 150 -H 28
    $bForm.Font = $script:FBold
    $sf.Controls.Add($bForm)

    $bCopy = New-W95Btn -Text "Copy catalog block" -X 168 -Y $y -W 150 -H 28
    $sf.Controls.Add($bCopy)

    $bClose = New-W95Btn -Text "Close" -X 510 -Y $y -W 100 -H 28
    $sf.Controls.Add($bClose)

    $bForm.Add_Click({ Open-ScriptHubRequestForm })

    $bCopy.Add_Click({
        if ($tN.Text.Trim() -eq "" -or $tScr.Text.Trim() -eq "") {
            [System.Windows.Forms.MessageBox]::Show("Name and Script are required.","ScriptHub","OK","Warning")
            return
        }
        $catValue = $tCat.Text.Trim()
        if ($catValue -eq "") { $catValue = "Other" }

        $block = New-ScriptHubCatalogEntry -Name $tN.Text.Trim() -Category $catValue -SubCategory $tSub.Text.Trim() -Description $tDesc.Text.Trim() -ScriptText $tScr.Text -PSVersion $tPSV.Text -Tags $tTags.Text.Trim() -Notes $tNotes.Text.Trim()

        [System.Windows.Forms.Clipboard]::SetText($block)
        [System.Windows.Forms.MessageBox]::Show("Catalog block copied. Attach it to your request; once approved it will be pasted into ScriptHub.Catalog.ps1.","ScriptHub","OK","Information")
    })

    $bClose.Add_Click({ $sf.Close() })
    $sf.CancelButton = $bClose

    [void]$sf.ShowDialog()
    $sf.Dispose()
}

# ============================================================================
# MAIN FORM
# ============================================================================
function Show-MainForm {

    try {
        [void](Initialize-ScriptHub)
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "The catalog could not be loaded:`n$($_.Exception.Message)",
            "ScriptHub",
            "OK",
            "Error")
        return
    }
    $ver = $global:ScriptHubConfig.Version

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ScriptHub v$ver"
    $form.Size = New-Object System.Drawing.Size(1060, 730)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = $script:C_Surface
    $form.Font = $script:FNormal
    $form.MinimumSize = New-Object System.Drawing.Size(900, 600)
    $form.KeyPreview = $true
    $form.Padding = New-Object System.Windows.Forms.Padding(0)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    try { $form.DoubleBuffered = $true } catch { }

    # Restore native edge and corner resizing for the borderless custom chrome.
    $resizeWindow = New-Object -TypeName ScriptHubResizeWindow -ArgumentList $form

    # --- TITLE BAR ---
    $pnlTitle = New-Object System.Windows.Forms.Panel
    $pnlTitle.Dock = [System.Windows.Forms.DockStyle]::Top
    $pnlTitle.Height = 40
    $pnlTitle.BackColor = $script:C_TitleBar
    $pnlTitle.Padding = New-Object System.Windows.Forms.Padding(0)
    $form.Controls.Add($pnlTitle)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "ScriptHub"
    $lblTitle.ForeColor = $script:C_White
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lblTitle.Dock = [System.Windows.Forms.DockStyle]::Fill
    $lblTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $lblTitle.Padding = New-Object System.Windows.Forms.Padding(14,0,0,0)
    $pnlTitle.Controls.Add($lblTitle)

    $pnlTitleButtons = New-Object System.Windows.Forms.Panel
    $pnlTitleButtons.Dock = [System.Windows.Forms.DockStyle]::Right
    $pnlTitleButtons.Width = 138
    $pnlTitleButtons.BackColor = [System.Drawing.Color]::Transparent
    $pnlTitle.Controls.Add($pnlTitleButtons)

    $btnMin = New-TitleBarButton -Text "—" -Action "min" -Width 46 -Height 40
    $btnMax = New-TitleBarButton -Text "□" -Action "max" -Width 46 -Height 40
    $btnClose = New-TitleBarButton -Text "✕" -Action "close" -Width 46 -Height 40
    $btnMin.Dock = [System.Windows.Forms.DockStyle]::Right
    $btnMax.Dock = [System.Windows.Forms.DockStyle]::Right
    $btnClose.Dock = [System.Windows.Forms.DockStyle]::Right
    $pnlTitleButtons.Controls.Add($btnMin)
    $pnlTitleButtons.Controls.Add($btnMax)
    $pnlTitleButtons.Controls.Add($btnClose)

    $btnMin.Add_Click({ $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized })
    $btnMax.Add_Click({
        if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Maximized) {
            $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
            $btnMax.Text = "□"
        } else {
            $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
            $btnMax.Text = "❐"
        }
    })
    $btnClose.Add_Click({ $form.Close() })

    function Enable-TitleBarDrag {
        param(
            [Parameter(Mandatory = $true)]
            [System.Windows.Forms.Control]$Control
        )

        $Control.Add_MouseDown({
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                [void][ScriptHubNative]::ReleaseCapture()
                [void][ScriptHubNative]::SendMessage($form.Handle, 0xA1, [IntPtr]2, [IntPtr]0)
            }
        })
    }

    Enable-TitleBarDrag -Control $pnlTitle
    Enable-TitleBarDrag -Control $lblTitle
    Enable-TitleBarDrag -Control $pnlTitleButtons

    # --- SEARCH PANEL ---
    $pnlSearch = New-Object System.Windows.Forms.Panel
    $pnlSearch.Dock = [System.Windows.Forms.DockStyle]::Top
    $pnlSearch.Height = 86
    $pnlSearch.BackColor = $script:C_Gray
    $form.Controls.Add($pnlSearch)

    $pnlSearch.Controls.Add((New-W95Lbl -Text "Search:" -X 10 -Y 12 -W 50 -Bold))

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(63, 9)
    $txtSearch.Size = New-Object System.Drawing.Size(380, 28)
    $txtSearch.Font = $script:FNormal
    $txtSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $txtSearch.BackColor = $script:C_White
    $txtSearch.ForeColor = $script:C_TextPrimary
    $txtSearch.Multiline = $false
    $pnlSearch.Controls.Add($txtSearch)

    $btnSearch = New-W95Btn -Text "Search" -X 450 -Y 8 -W 80 -H 30
    $btnSearch.BackColor = $script:C_Accent
    $btnSearch.ForeColor = $script:C_White
    $btnSearch.FlatAppearance.BorderColor = $script:C_Accent
    $btnSearch.FlatAppearance.MouseOverBackColor = $script:C_AccentHover
    $btnSearch.FlatAppearance.MouseDownBackColor = $script:C_AccentPressed
    $pnlSearch.Controls.Add($btnSearch)
    $btnClear = New-W95Btn -Text "Clear" -X 535 -Y 8 -W 75 -H 30
    $pnlSearch.Controls.Add($btnClear)

    $pnlSearch.Controls.Add((New-W95Lbl -Text "Category:" -X 10 -Y 48 -W 65 -Bold))

    $cmbCat = New-Object System.Windows.Forms.ComboBox
    $cmbCat.Location = New-Object System.Drawing.Point(78, 45)
    $cmbCat.Size = New-Object System.Drawing.Size(170, 28)
    $cmbCat.Font = $script:FNormal
    $cmbCat.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbCat.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cmbCat.BackColor = $script:C_White
    $cmbCat.ForeColor = $script:C_TextPrimary
    $pnlSearch.Controls.Add($cmbCat)

    $pnlSearch.Controls.Add((New-W95Lbl -Text "PS Ver:" -X 260 -Y 48 -W 50 -Bold))

    $cmbPS = New-Object System.Windows.Forms.ComboBox
    $cmbPS.Location = New-Object System.Drawing.Point(313, 45)
    $cmbPS.Size = New-Object System.Drawing.Size(100, 28)
    $cmbPS.Font = $script:FNormal
    $cmbPS.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbPS.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cmbPS.BackColor = $script:C_White
    $cmbPS.ForeColor = $script:C_TextPrimary
    $cmbPS.Items.AddRange(@("All","5","7","5 & 7","N/A"))
    $cmbPS.SelectedIndex = 0
    $pnlSearch.Controls.Add($cmbPS)

    $pnlSearch.Controls.Add((New-W95Lbl -Text "Team:" -X 425 -Y 48 -W 45 -Bold))

    $cmbTeam = New-Object System.Windows.Forms.ComboBox
    $cmbTeam.Location = New-Object System.Drawing.Point(472, 45)
    $cmbTeam.Size = New-Object System.Drawing.Size(135, 28)
    $cmbTeam.Font = $script:FNormal
    $cmbTeam.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbTeam.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cmbTeam.BackColor = $script:C_White
    $cmbTeam.ForeColor = $script:C_TextPrimary
    $pnlSearch.Controls.Add($cmbTeam)

    $lblCount = New-W95Lbl -Text "Results: 0" -X 620 -Y 12 -W 160 -Bold
    $pnlSearch.Controls.Add($lblCount)

    $btnSuggest  = New-W95Btn -Text "Suggest" -X 620 -Y 41 -W 95 -H 30
    $btnFeedback = New-W95Btn -Text "Feedback" -X 720 -Y 41 -W 90 -H 30
    $btnSite     = New-W95Btn -Text "Open Site" -X 815 -Y 41 -W 90 -H 30
    $btnReload   = New-W95Btn -Text "Reload" -X 910 -Y 41 -W 90 -H 30
    $pnlSearch.Controls.Add($btnSuggest)
    $pnlSearch.Controls.Add($btnFeedback)
    $pnlSearch.Controls.Add($btnSite)
    $pnlSearch.Controls.Add($btnReload)

    # --- STATUS BAR ---
    $statusBar = New-Object System.Windows.Forms.Label
    $statusBar.Text = " ScriptHub v$ver | $($global:ScriptHubConfig.Author) | Scripts: $($global:Commands.Count)"
    $statusBar.Font = $script:FNormal
    $statusBar.Height = 26
    $statusBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $statusBar.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $statusBar.Padding = New-Object System.Windows.Forms.Padding(10,0,0,0)
    $statusBar.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $statusBar.ForeColor = $script:C_TextSecondary
    $statusBar.BackColor = $script:C_SurfaceAlt
    $statusBar.Margin = New-Object System.Windows.Forms.Padding(0)
    $form.Controls.Add($statusBar)

    # --- SPLIT CONTAINER ---
    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Dock = [System.Windows.Forms.DockStyle]::Fill
    $split.Orientation = [System.Windows.Forms.Orientation]::Horizontal
    $split.SplitterDistance = 250
    $split.BackColor = $script:C_Gray
    $split.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $form.Controls.Add($split)

    # Keep the custom chrome on top and the content below it.
    $form.Controls.SetChildIndex($split, 0)
    $form.Controls.SetChildIndex($statusBar, 1)
    $form.Controls.SetChildIndex($pnlSearch, 2)
    $form.Controls.SetChildIndex($pnlTitle, $form.Controls.Count - 1)

    # --- LISTVIEW ---
    $lv = New-Object System.Windows.Forms.ListView
    $lv.Dock = [System.Windows.Forms.DockStyle]::Fill
    $lv.View = [System.Windows.Forms.View]::Details
    $lv.FullRowSelect = $true
    $lv.GridLines = $false
    $lv.Font = $script:FNormal
    $lv.BackColor = $script:C_White
    $lv.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $lv.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
    $lv.MultiSelect = $false
    $lv.HideSelection = $false
    [void]$lv.Columns.Add("Name", 205)
    [void]$lv.Columns.Add("Team", 100)
    [void]$lv.Columns.Add("Category", 115)
    [void]$lv.Columns.Add("SubCategory", 115)
    [void]$lv.Columns.Add("PS Ver", 80)
    [void]$lv.Columns.Add("Description", 370)
    $split.Panel1.Controls.Add($lv)

    # --- CONTEXT MENU ---
    $ctx = New-Object System.Windows.Forms.ContextMenuStrip
    $ctxCopy    = New-Object System.Windows.Forms.ToolStripMenuItem("Copy Script")
    $ctxSavePS1 = New-Object System.Windows.Forms.ToolStripMenuItem("Save as .ps1")
    $ctxRun     = New-Object System.Windows.Forms.ToolStripMenuItem("Run...")
    [void]$ctx.Items.AddRange(@($ctxCopy, $ctxSavePS1, $ctxRun))
    $lv.ContextMenuStrip = $ctx

    # --- DETAIL PANEL ---
    $pnlDetail = New-Object System.Windows.Forms.Panel
    $pnlDetail.Dock = [System.Windows.Forms.DockStyle]::Fill
    $pnlDetail.BackColor = $script:C_White
    $split.Panel2.Controls.Add($pnlDetail)

    $pnlInfo = New-Object System.Windows.Forms.Panel
    $pnlInfo.Dock = [System.Windows.Forms.DockStyle]::Top
    $pnlInfo.Height = 52
    $pnlInfo.BackColor = $script:C_White
    $pnlDetail.Controls.Add($pnlInfo)

    $pnlDeps = New-Object System.Windows.Forms.Panel
    $pnlDeps.Dock = [System.Windows.Forms.DockStyle]::Top
    $pnlDeps.Height = 58
    $pnlDeps.BackColor = [System.Drawing.Color]::FromArgb(250,251,253)
    $pnlDeps.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pnlDetail.Controls.Add($pnlDeps)

    $lblDeps = New-Object System.Windows.Forms.Label
    $lblDeps.Text = "Dependencies: select a script"
    $lblDeps.Location = New-Object System.Drawing.Point(8, 7)
    $lblDeps.Size = New-Object System.Drawing.Size(430, 42)
    $lblDeps.Font = $script:FNormal
    $lblDeps.ForeColor = $script:C_DarkGray
    $lblDeps.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $pnlDeps.Controls.Add($lblDeps)

    $btnInstallDeps = New-W95Btn -Text "Install modules" -X 620 -Y 14 -W 135 -H 28
    $btnInstallDeps.Font = $script:FBold
    $btnInstallDeps.Enabled = $false
    $btnInstallDeps.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $pnlDeps.Controls.Add($btnInstallDeps)

    $btnInstallPS7 = New-W95Btn -Text "Get PowerShell 7" -X 765 -Y 14 -W 135 -H 28
    $btnInstallPS7.Enabled = $false
    $btnInstallPS7.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $pnlDeps.Controls.Add($btnInstallPS7)

    $pnlDeps.Add_Resize({
        $rightPad = 14
        $gap = 12
        $btnW = 135
        $btnH = 28
        $btnY = 14
        $x1 = $this.Width - ($btnW + $rightPad)
        $x2 = $x1 - ($btnW + $gap)
        $btnInstallDeps.Location = New-Object System.Drawing.Point($x2, $btnY)
        $btnInstallPS7.Location = New-Object System.Drawing.Point($x1, $btnY)
        $lblDeps.Width = [Math]::Max(180, ($x2 - 20))
    })

    $lblDName = New-Object System.Windows.Forms.Label
    $lblDName.Text = "Select a script to view details"
    $lblDName.Location = New-Object System.Drawing.Point(6, 3)
    $lblDName.Size = New-Object System.Drawing.Size(500, 16)
    $lblDName.Font = $script:FBold
    $lblDName.ForeColor = $script:C_Navy
    $pnlInfo.Controls.Add($lblDName)

    $lblDTags = New-Object System.Windows.Forms.Label
    $lblDTags.Location = New-Object System.Drawing.Point(6, 20)
    $lblDTags.Size = New-Object System.Drawing.Size(500, 14)
    $lblDTags.Font = $script:FNormal
    $lblDTags.ForeColor = $script:C_DarkGray
    $pnlInfo.Controls.Add($lblDTags)

    $lblDNotes = New-Object System.Windows.Forms.Label
    $lblDNotes.Location = New-Object System.Drawing.Point(6, 35)
    $lblDNotes.Size = New-Object System.Drawing.Size(500, 14)
    $lblDNotes.Font = $script:FNormal
    $lblDNotes.ForeColor = $script:C_DarkRed
    $pnlInfo.Controls.Add($lblDNotes)

    $arrow2 = [string][char]9654
    $btnRun = New-W95Btn -Text ($arrow2 + " Run") -X 520 -Y 6 -W 100
    $btnRun.Font = $script:FBold
    $btnRun.BackColor = $script:C_Accent
    $btnRun.ForeColor = $script:C_White
    $btnRun.FlatAppearance.BorderColor = $script:C_Accent
    $btnRun.FlatAppearance.MouseOverBackColor = $script:C_AccentHover
    $pnlInfo.Controls.Add($btnRun)

    $btnSavePS1 = New-W95Btn -Text "Save .ps1" -X 630 -Y 6 -W 100
    $btnSavePS1.Font = $script:FBold
    $pnlInfo.Controls.Add($btnSavePS1)

    $btnCopy = New-W95Btn -Text "Copy Script" -X 740 -Y 6 -W 110
    $btnCopy.Font = $script:FBold
    $pnlInfo.Controls.Add($btnCopy)
    $btnRun.Enabled = $false
    $btnSavePS1.Enabled = $false
    $btnCopy.Enabled = $false

    # --- Script display ---
    $txtScript = New-Object System.Windows.Forms.RichTextBox
    $txtScript.Dock = [System.Windows.Forms.DockStyle]::Fill
    $txtScript.Font = $script:FMono
    $txtScript.BackColor = $script:C_TermBG
    $txtScript.ForeColor = $script:C_TermFG
    $txtScript.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $txtScript.ReadOnly = $true
    $txtScript.WordWrap = $false
    $txtScript.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Both
    $pnlDetail.Controls.Add($txtScript)
    $txtScript.BringToFront()

    # === INTERNAL UI HELPERS ===

    function Update-CatFilter {
        $sel = $cmbCat.Text
        $cmbCat.Items.Clear()
        foreach ($c in (Get-ScriptHubCategory)) { [void]$cmbCat.Items.Add($c) }
        $idx = $cmbCat.Items.IndexOf($sel)
        if ($idx -ge 0) { $cmbCat.SelectedIndex = $idx } else { $cmbCat.SelectedIndex = 0 }
    }

    function Update-TeamFilter {
        $sel = $cmbTeam.Text
        $cmbTeam.Items.Clear()
        foreach ($team in (Get-ScriptHubTeam)) { [void]$cmbTeam.Items.Add($team) }
        $idx = $cmbTeam.Items.IndexOf($sel)
        if ($idx -ge 0) { $cmbTeam.SelectedIndex = $idx } else { $cmbTeam.SelectedIndex = 0 }
    }

    function Update-LV {
        param([string]$S="",[string]$CF="All",[string]$PF="All",[string]$TF="All")
        $lv.Items.Clear()
        foreach ($cmd in (Select-ScriptHubCommand -SearchText $S -Category $CF -PSVersion $PF -Team $TF)) {
            $item = New-Object System.Windows.Forms.ListViewItem($cmd.Name)
            [void]$item.SubItems.Add($cmd.Team)
            [void]$item.SubItems.Add($cmd.Category)
            [void]$item.SubItems.Add($cmd.SubCategory)
            [void]$item.SubItems.Add($cmd.PSVersion)
            [void]$item.SubItems.Add($cmd.Description)
            $item.Tag = $cmd.Id
            [void]$lv.Items.Add($item)
        }
        $lblCount.Text = "Results: $($lv.Items.Count)"
        $statusBar.Text = " ScriptHub v$ver | Total: $($global:Commands.Count) | Showing: $($lv.Items.Count)"
    }

    function Show-Detail {
        param([string]$Id)
        $cmd = Get-ScriptHubCommandById -Id $Id
        if ($cmd) {
            $deps = Get-ScriptHubDependencies -Command $cmd
            $lblDName.Text  = "$($cmd.Name)  [$($cmd.Team) > $($cmd.Category) > $($cmd.SubCategory)]  [PS $($cmd.PSVersion)]"
            $lblDTags.Text  = "Tags: $($cmd.Tags)"
            $lblDNotes.Text = "$($cmd.Notes)"
            $moduleText = if (@($deps.ModuleStatus).Count -gt 0) {
                @($deps.ModuleStatus | ForEach-Object {
                    if ($_.Installed) { "$($_.Name) $($_.Version)" } else { "$($_.Name) (missing)" }
                }) -join ', '
            } else { 'None detected' }
            $psText = if ($deps.RequiresPowerShell7) { 'PowerShell 7 required' } else { "PowerShell $($deps.PowerShellVersion)" }
            $lblDeps.Text = "Dependencies: $moduleText`nRuntime: $psText"
            $txtScript.Text = $cmd.Script
            $btnRun.Enabled = $true
            $btnSavePS1.Enabled = $true
            $btnCopy.Enabled = $true
            $btnInstallDeps.Enabled = @($deps.MissingModules).Count -gt 0
            $btnInstallPS7.Enabled = $deps.RequiresPowerShell7
        }
    }

    function Get-SelectedId {
        if ($lv.SelectedItems.Count -gt 0) { return $lv.SelectedItems[0].Tag }
        return $null
    }

    # === EVENT HANDLERS ===
    $doSearch = { Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text -TF $cmbTeam.Text }

    $btnSearch.Add_Click($doSearch)

    $txtSearch.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text -TF $cmbTeam.Text
            $_.SuppressKeyPress = $true
        }
    })

    $btnClear.Add_Click({
        $txtSearch.Text = ""
        $cmbCat.SelectedIndex = 0
        $cmbPS.SelectedIndex = 0
        $cmbTeam.SelectedIndex = 0
        Update-LV -TF $cmbTeam.Text
        $lblDName.Text = "Select a script to view details"
        $lblDTags.Text = ""
        $lblDNotes.Text = ""
        $lblDeps.Text = "Dependencies: select a script"
        $txtScript.Text = ""
        $btnRun.Enabled = $false
        $btnSavePS1.Enabled = $false
        $btnCopy.Enabled = $false
        $btnInstallDeps.Enabled = $false
        $btnInstallPS7.Enabled = $false
    })

    $cmbCat.Add_SelectedIndexChanged($doSearch)
    $cmbPS.Add_SelectedIndexChanged($doSearch)
    $cmbTeam.Add_SelectedIndexChanged($doSearch)

    $lv.Add_SelectedIndexChanged({
        $id = Get-SelectedId
        if ($id) { Show-Detail -Id $id }
    })

    $lv.Add_DoubleClick({
        if ($txtScript.Text -ne "") {
            [System.Windows.Forms.Clipboard]::SetText($txtScript.Text)
            $statusBar.Text = " Script copied to clipboard"
        }
    })

    $btnCopy.Add_Click({
        if ($txtScript.Text -ne "") {
            [System.Windows.Forms.Clipboard]::SetText($txtScript.Text)
            $statusBar.Text = " Script copied to clipboard"
        }
    })

    $btnSavePS1.Add_Click({
        $id = Get-SelectedId
        if (-not $id) {
            [System.Windows.Forms.MessageBox]::Show("Select a script first.","Info","OK","Information")
            return
        }
        $cmd = Get-ScriptHubCommandById -Id $id
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.FileName = ($cmd.Name -replace '[^\w\-]','_') + ".ps1"
        $sfd.Filter = "PowerShell Script (*.ps1)|*.ps1|All files (*.*)|*.*"
        $sfd.Title = "Save script as .ps1"
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                [void](Save-ScriptHubScript -ScriptText $cmd.Script -Path $sfd.FileName)
                $statusBar.Text = " Saved: $($sfd.FileName)"
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Could not save the script:`n$($_.Exception.Message)", "Save error", "OK", "Error")
            }
        }
    })

    $btnRun.Add_Click({
        $id = Get-SelectedId
        if (-not $id) {
            [System.Windows.Forms.MessageBox]::Show("Select a script first.","Info","OK","Information")
            return
        }
        $cmd = Get-ScriptHubCommandById -Id $id
        Show-RunForm -ScriptText $cmd.Script -CmdName $cmd.Name -PSVersion $cmd.PSVersion
    })

    $btnInstallDeps.Add_Click({
        $id = Get-SelectedId
        if (-not $id) { return }
        try {
            $cmd = Get-ScriptHubCommandById -Id $id
            $deps = Get-ScriptHubDependencies -Command $cmd
            $confirm = [System.Windows.Forms.MessageBox]::Show(
                "Install missing modules for '$($cmd.Name)'?`n`n$(@($deps.MissingModules) -join "`n")",
                "Confirm dependency installation",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            [void](Install-ScriptHubDependencies -Dependencies $deps -CommandName $cmd.Name)
            $statusBar.Text = " Dependency installer opened for: $($cmd.Name)"
        } catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Dependency installation", "OK", "Warning")
        }
    })

    $btnInstallPS7.Add_Click({
        try {
            Open-ScriptHubUrl -Url $global:ScriptHubConfig.PowerShell7Url -Label 'PowerShell 7 URL'
        } catch {
            [System.Diagnostics.Process]::Start('https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows')
        }
    })

    $btnSuggest.Add_Click({
        try { Show-SubmitForm }
        catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "ScriptHub", "OK", "Error") }
    })
    $btnFeedback.Add_Click({
        try { Open-ScriptHubFeedbackForm }
        catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "ScriptHub", "OK", "Error") }
    })
    $btnSite.Add_Click({
        try { Open-ScriptHubUrl -Url $global:ScriptHubConfig.SiteUrl -Label 'Site URL' }
        catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "ScriptHub", "OK", "Error") }
    })

    # Reload re-reads the catalog file so approved additions show up without restarting
    $btnReload.Add_Click({
        try {
            . (Join-Path $here 'ScriptHub.Catalog.ps1')
            [void](Initialize-ScriptHub)
            Update-CatFilter
            Update-TeamFilter
            Update-LV -S $txtSearch.Text -CF $cmbCat.Text -PF $cmbPS.Text -TF $cmbTeam.Text
            $statusBar.Text = " Catalog reloaded | Scripts: $($global:Commands.Count)"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("The catalog could not be reloaded:`n$($_.Exception.Message)", "Reload error", "OK", "Error")
        }
    })

    $ctxCopy.Add_Click({ $btnCopy.PerformClick() })
    $ctxSavePS1.Add_Click({ $btnSavePS1.PerformClick() })
    $ctxRun.Add_Click({ $btnRun.PerformClick() })

    # --- Keyboard shortcuts ---
    $form.Add_KeyDown({
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::F) { $txtSearch.Focus(); $_.Handled = $true }
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::R) { $btnRun.PerformClick(); $_.Handled = $true }
        if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::N) { $btnSuggest.PerformClick(); $_.Handled = $true }
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::F5) { $btnReload.PerformClick(); $_.Handled = $true }
    })

    # === INITIALIZE ===
    Update-CatFilter
    Update-TeamFilter
    Update-LV -TF $cmbTeam.Text

    Set-RoundedCorners -Control $form -Radius 12
    $form.Add_Resize({ Set-RoundedCorners -Control $this -Radius 12 })
    [void]$form.ShowDialog()
    $resizeWindow.Dispose()
    $form.Dispose()
}

# === LAUNCH ===
Show-MainForm
