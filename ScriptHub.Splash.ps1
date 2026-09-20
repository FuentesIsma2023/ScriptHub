# ============================================================================
# ScriptHub.Splash.ps1 - Windows 95-inspired launch screen
# Loaded by ScriptHub.UI.ps1.
# ============================================================================

function New-ScriptHubSplashButton {
    param([string]$Text,[int]$Width=120,[int]$Height=30)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = New-Object System.Drawing.Size($Width,$Height)
    $button.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9)
    $button.BackColor = [System.Drawing.Color]::FromArgb(192,192,192)
    $button.ForeColor = [System.Drawing.Color]::Black
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $button.UseVisualStyleBackColor = $false
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $button
}

function Show-ScriptHubSplash {
    $desktopBlue = [System.Drawing.Color]::FromArgb(0,128,160)
    $windowGray = [System.Drawing.Color]::FromArgb(192,192,192)
    $titleBlue = [System.Drawing.Color]::FromArgb(0,0,128)
    $ink = [System.Drawing.Color]::FromArgb(32,32,32)
    $screenBlue = [System.Drawing.Color]::FromArgb(0,64,128)

    $splash = New-Object System.Windows.Forms.Form
    $splash.Text = "ScriptHub"
    $splash.ClientSize = New-Object System.Drawing.Size(780,520)
    $splash.MinimumSize = New-Object System.Drawing.Size(640,440)
    $splash.StartPosition = "CenterScreen"
    $splash.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $splash.BackColor = $desktopBlue
    $splash.Padding = New-Object System.Windows.Forms.Padding(0)
    $splash.Opacity = 0.0
    $resizeWindow = New-Object -TypeName ScriptHubResizeWindow -ArgumentList $splash

    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Dock = [System.Windows.Forms.DockStyle]::Top
    $titleBar.Height = 30
    $titleBar.BackColor = $titleBlue
    $splash.Controls.Add($titleBar)

    $titleText = New-Object System.Windows.Forms.Label
    $titleText.Text = "ScriptHub"
    $titleText.Dock = [System.Windows.Forms.DockStyle]::Fill
    $titleText.ForeColor = [System.Drawing.Color]::White
    $titleText.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9,[System.Drawing.FontStyle]::Bold)
    $titleText.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $titleText.Padding = New-Object System.Windows.Forms.Padding(8,0,0,0)
    $titleBar.Controls.Add($titleText)

    $closeSplash = New-ScriptHubSplashButton -Text "X" -Width 28 -Height 22
    $closeSplash.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8,[System.Drawing.FontStyle]::Bold)
    $closeSplash.Dock = [System.Windows.Forms.DockStyle]::Right
    $titleBar.Controls.Add($closeSplash)

    foreach ($dragControl in @($titleBar,$titleText)) {
        $dragControl.Add_MouseDown({
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                [void][ScriptHubNative]::ReleaseCapture()
                [void][ScriptHubNative]::SendMessage($splash.Handle,0xA1,[IntPtr]2,[IntPtr]0)
            }
        }.GetNewClosure())
    }

    $workspace = New-Object System.Windows.Forms.Panel
    $workspace.Dock = [System.Windows.Forms.DockStyle]::Fill
    $workspace.BackColor = $desktopBlue
    $splash.Controls.Add($workspace)

    $window = New-Object System.Windows.Forms.Panel
    $window.Location = New-Object System.Drawing.Point(32,28)
    $window.Size = New-Object System.Drawing.Size(716,420)
    $window.MinimumSize = New-Object System.Drawing.Size(576,340)
    $window.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $window.BackColor = $windowGray
    $window.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $workspace.Controls.Add($window)

    $centerWindow = {
        $availableWidth = $workspace.ClientSize.Width
        $availableHeight = $workspace.ClientSize.Height
        $window.Location = New-Object System.Drawing.Point(
            [Math]::Max(0,[int](($availableWidth - $window.Width) / 2)),
            [Math]::Max(0,[int](($availableHeight - $window.Height) / 2)))
    }.GetNewClosure()
    $workspace.Add_Resize($centerWindow)
    & $centerWindow

    $brand = New-Object System.Windows.Forms.Label
    $brand.Text = "ScriptHub"
    $brand.Location = New-Object System.Drawing.Point(28,22)
    $brand.Size = New-Object System.Drawing.Size(620,42)
    $brand.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $brand.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",24,[System.Drawing.FontStyle]::Bold)
    $brand.ForeColor = $ink
    $window.Controls.Add($brand)

    $version = New-Object System.Windows.Forms.Label
    $version.Text = "INTERNAL SCRIPT CATALOG  |  VERSION 4.0"
    $version.Location = New-Object System.Drawing.Point(31,64)
    $version.Size = New-Object System.Drawing.Size(620,18)
    $version.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $version.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8,[System.Drawing.FontStyle]::Bold)
    $version.ForeColor = $titleBlue
    $window.Controls.Add($version)

    $computer = New-Object System.Windows.Forms.Panel
    $computer.Location = New-Object System.Drawing.Point(30,108)
    $computer.Size = New-Object System.Drawing.Size(170,142)
    $computer.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $computer.BackColor = [System.Drawing.Color]::FromArgb(160,160,160)
    $computer.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $window.Controls.Add($computer)

    $monitor = New-Object System.Windows.Forms.Panel
    $monitor.Location = New-Object System.Drawing.Point(14,10)
    $monitor.Size = New-Object System.Drawing.Size(142,86)
    $monitor.BackColor = [System.Drawing.Color]::FromArgb(224,224,224)
    $monitor.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $computer.Controls.Add($monitor)

    $screen = New-Object System.Windows.Forms.Label
    $screen.Text = "C:\>_"
    $screen.Location = New-Object System.Drawing.Point(8,8)
    $screen.Size = New-Object System.Drawing.Size(118,62)
    $screen.BackColor = $screenBlue
    $screen.ForeColor = [System.Drawing.Color]::White
    $screen.Font = New-Object System.Drawing.Font("Courier New",10,[System.Drawing.FontStyle]::Bold)
    $screen.Padding = New-Object System.Windows.Forms.Padding(5,5,0,0)
    $monitor.Controls.Add($screen)

    $stand = New-Object System.Windows.Forms.Panel
    $stand.Location = New-Object System.Drawing.Point(66,96)
    $stand.Size = New-Object System.Drawing.Size(38,14)
    $stand.BackColor = [System.Drawing.Color]::FromArgb(128,128,128)
    $computer.Controls.Add($stand)

    $keyboard = New-Object System.Windows.Forms.Panel
    $keyboard.Location = New-Object System.Drawing.Point(24,115)
    $keyboard.Size = New-Object System.Drawing.Size(122,16)
    $keyboard.BackColor = [System.Drawing.Color]::FromArgb(224,224,224)
    $keyboard.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $computer.Controls.Add($keyboard)

    $message = New-Object System.Windows.Forms.Label
    $message.Text = "Reliving the Legacy.`nBuilding the Future."
    $message.Location = New-Object System.Drawing.Point(232,112)
    $message.Size = New-Object System.Drawing.Size(430,58)
    $message.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $message.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",15,[System.Drawing.FontStyle]::Bold)
    $message.ForeColor = $titleBlue
    $window.Controls.Add($message)

    $statement = New-Object System.Windows.Forms.Label
    $statement.Text = "Empowering the past.`nInnovating the present.`nInspiring the future."
    $statement.Location = New-Object System.Drawing.Point(232,180)
    $statement.Size = New-Object System.Drawing.Size(430,72)
    $statement.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $statement.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",11)
    $statement.ForeColor = $ink
    $window.Controls.Add($statement)

    $footer = New-Object System.Windows.Forms.Label
    $footer.Text = "Built with passion. For the team. For the legacy."
    $footer.Location = New-Object System.Drawing.Point(30,274)
    $footer.Size = New-Object System.Drawing.Size(620,20)
    $footer.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $footer.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9,[System.Drawing.FontStyle]::Italic)
    $footer.ForeColor = $ink
    $window.Controls.Add($footer)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = "Ready to launch."
    $status.Location = New-Object System.Drawing.Point(30,306)
    $status.Size = New-Object System.Drawing.Size(280,20)
    $status.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $status.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8)
    $status.ForeColor = [System.Drawing.Color]::FromArgb(80,80,80)
    $window.Controls.Add($status)

    $releaseNotes = New-ScriptHubSplashButton -Text "Release Notes" -Width 120 -Height 30
    $releaseNotes.Location = New-Object System.Drawing.Point(390,300)
    $releaseNotes.Anchor = [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $window.Controls.Add($releaseNotes)

    $launch = New-ScriptHubSplashButton -Text "Launch Tool" -Width 120 -Height 30
    $launch.Location = New-Object System.Drawing.Point(522,300)
    $launch.Anchor = [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $launch.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9,[System.Drawing.FontStyle]::Bold)
    $window.Controls.Add($launch)

    $releaseNotes.Add_Click({
        [System.Windows.Forms.MessageBox]::Show(
            "ScriptHub v4.0`n`nA classic Windows-inspired launch experience for the modern internal script catalog.",
            "ScriptHub Release Notes","OK","Information")
    })
    $launch.Add_Click({ $splash.Tag = "launch"; $splash.Close() })
    $closeSplash.Add_Click({ $splash.Close() })
    $splash.AcceptButton = $launch

    $fadeTimer = New-Object System.Windows.Forms.Timer
    $fadeTimer.Interval = 35
    $fadeTimer.Add_Tick({
        $splash.Opacity = [Math]::Min(1.0,($splash.Opacity + 0.12))
        if ($splash.Opacity -ge 1.0) { $fadeTimer.Stop(); $fadeTimer.Dispose() }
    }.GetNewClosure())
    $fadeTimer.Start()

    [void]$splash.ShowDialog()
    if ($fadeTimer -and $fadeTimer.Enabled) { $fadeTimer.Stop(); $fadeTimer.Dispose() }
    $launchRequested = ($splash.Tag -eq "launch")
    $resizeWindow.Dispose()
    $splash.Dispose()
    return $launchRequested
}
