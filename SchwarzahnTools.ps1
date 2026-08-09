#Requires -Version 5.1
<#
.SYNOPSIS
  Schwarzahn Tools — SS tool hub (download / launch / search)
  by Schwarzahn

  Categories: Schwarzahn scripts + OrbDiff / Spokwn / Zimmerman / NirSoft / …
  Tools land in %LOCALAPPDATA%\Schwarzahn\Tools
#>

$ErrorActionPreference = 'Stop'
$esc = [char]27

function Test-IsAdmin {
    $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Self {
    param([switch]$AsAdmin)
    $path = $PSCommandPath
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) { return $false }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'powershell.exe'
    $psi.Arguments = "-NoProfile -STA -ExecutionPolicy Bypass -File `"$path`""
    $psi.UseShellExecute = $true
    if ($AsAdmin) { $psi.Verb = 'runas' }
    try { [void][Diagnostics.Process]::Start($psi); return $true } catch { return $false }
}

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    if (Restart-Self) { exit }
    Write-Error 'Need STA: powershell -NoProfile -STA -ExecutionPolicy Bypass -File .\SchwarzahnTools.ps1'
    exit 1
}

if (-not (Test-IsAdmin)) {
    if (Restart-Self -AsAdmin) { exit }
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Net.Http | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:Brand = 'Schwarzahn'
$script:AppName = 'Schwarzahn Tools'
$script:AppVersion = '1.0'
$script:RepoRaw = 'https://raw.githubusercontent.com/Schwarzahn/Windows-ScreenShare-Tool/main'
$script:CatalogUrl = "$script:RepoRaw/ToolsCatalog.json"

$localRoot = Join-Path $env:LOCALAPPDATA 'Schwarzahn'
$script:ToolsRoot = Join-Path $localRoot 'Tools'
$script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) 'SchwarzahnTools'
foreach ($d in @($localRoot, $script:ToolsRoot, $script:TempRoot)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Get-Catalog {
    $local = $null
    if ($PSCommandPath) {
        $cand = Join-Path (Split-Path -Parent $PSCommandPath) 'ToolsCatalog.json'
        if (Test-Path -LiteralPath $cand) { $local = $cand }
    }
    $here = Join-Path (Get-Location) 'ToolsCatalog.json'
    if (-not $local -and (Test-Path -LiteralPath $here)) { $local = $here }

    if ($local) {
        return (Get-Content -LiteralPath $local -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    $json = Invoke-RestMethod -Uri $script:CatalogUrl -UseBasicParsing
    return $json
}

function Get-SafeName([string]$Name) {
    ($Name -replace '[^\w\-. ]', '_').Trim()
}

function Get-ToolFolder($Tool) {
    Join-Path $script:ToolsRoot (Join-Path $Tool.Category (Get-SafeName $Tool.Name))
}

function Find-Launchable([string]$Dir) {
    if (-not (Test-Path -LiteralPath $Dir)) { return $null }
    $prefer = @('*.exe', '*.bat', '*.cmd', '*.ps1')
    foreach ($pat in $prefer) {
        $hit = Get-ChildItem -LiteralPath $Dir -Recurse -File -Filter $pat -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '(?i)uninstall|setup|vcredist|windowsdesktop-runtime' } |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Expand-IfZip([string]$File, [string]$Dest) {
    if ($File -match '(?i)\.zip$') {
        Expand-Archive -LiteralPath $File -DestinationPath $Dest -Force
        Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue
    }
}

function Resolve-GitHubLatestAsset([string]$Url) {
    # https://github.com/owner/repo/releases/latest → first asset browser_download_url
    if ($Url -notmatch 'github\.com/([^/]+)/([^/]+)/releases/latest/?$') { return $Url }
    $owner = $Matches[1]; $repo = $Matches[2]
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/latest" -Headers @{ 'User-Agent' = 'SchwarzahnTools' }
        $asset = $rel.assets | Where-Object { $_.name -match '\.(exe|zip|msi)$' } | Select-Object -First 1
        if ($asset) { return [string]$asset.browser_download_url }
    } catch {}
    return $Url
}

function Save-ToolDownload($Tool, [scriptblock]$Status) {
    $folder = Get-ToolFolder $Tool
    if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
    $link = [string]$Tool.Links[0]
    $link = Resolve-GitHubLatestAsset $link
    if ($link -notmatch '(?i)\.(exe|zip|msi)(\?|$)') {
        Start-Process $link
        & $Status "Opened download page in browser: $($Tool.Name)"
        return $null
    }
    $name = Split-Path -Leaf ($link -split '\?')[0]
    $dest = Join-Path $folder $name
    & $Status "Downloading $($Tool.Name)…"
    Invoke-WebRequest -Uri $link -OutFile $dest -UseBasicParsing
    Expand-IfZip $dest $folder
    $launch = Find-Launchable $folder
    & $Status ("Ready: {0}" -f $(if ($launch) { $launch } else { $folder }))
    return $launch
}

function Start-ToolScript($Tool) {
    $cmd = [string]$Tool.Command
    if ([string]::IsNullOrWhiteSpace($cmd)) { throw 'No Command on script tool' }
    $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
    Start-Process -FilePath 'powershell.exe' -ArgumentList $arg -WorkingDirectory $env:SystemRoot
}

function Clear-DownloadedTools {
    Get-ChildItem -LiteralPath $script:ToolsRoot -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# ===== UI =====
$catalog = Get-Catalog
$script:AllTools = @($catalog.tools)
$script:Categories = @($catalog.categories)

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Schwarzahn Tools" Height="640" Width="980"
        WindowStartupLocation="CenterScreen" Background="#140000"
        FontFamily="Segoe UI">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="200"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <DockPanel Grid.Row="0" Grid.ColumnSpan="2" Margin="0,0,0,10">
      <TextBlock DockPanel.Dock="Left" Text="SCHWARZAHN TOOLS" FontSize="22" FontWeight="Bold" Foreground="#FF2B2B" VerticalAlignment="Center"/>
      <TextBlock DockPanel.Dock="Right" Text="v1.0 · by Schwarzahn" Foreground="#888" VerticalAlignment="Center" Margin="12,0,0,0"/>
      <TextBox x:Name="SearchBox" Margin="24,0,0,0" Height="30" VerticalContentAlignment="Center"
               Background="#1E0000" Foreground="#EEE" BorderBrush="#5A1010" CaretBrush="#FF5555"
               ToolTip="Search BAM, Prefetch, Fileless, USB…"/>
    </DockPanel>

    <Border Grid.Row="1" Grid.Column="0" Background="#1A0000" BorderBrush="#3A0A0A" BorderThickness="1" CornerRadius="4" Margin="0,0,10,0">
      <ListBox x:Name="CatList" Background="Transparent" BorderThickness="0" Foreground="#DDD"
               ScrollViewer.HorizontalScrollBarVisibility="Disabled">
        <ListBox.ItemContainerStyle>
          <Style TargetType="ListBoxItem">
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="Foreground" Value="#CCC"/>
            <Setter Property="Template">
              <Setter.Value>
                <ControlTemplate TargetType="ListBoxItem">
                  <Border x:Name="Bd" Background="Transparent" Padding="{TemplateBinding Padding}">
                    <ContentPresenter/>
                  </Border>
                  <ControlTemplate.Triggers>
                    <Trigger Property="IsSelected" Value="True">
                      <Setter TargetName="Bd" Property="Background" Value="#3A0000"/>
                      <Setter Property="Foreground" Value="#FF5555"/>
                    </Trigger>
                    <Trigger Property="IsMouseOver" Value="True">
                      <Setter TargetName="Bd" Property="Background" Value="#2A0000"/>
                    </Trigger>
                  </ControlTemplate.Triggers>
                </ControlTemplate>
              </Setter.Value>
            </Setter>
          </Style>
        </ListBox.ItemContainerStyle>
      </ListBox>
    </Border>

    <DockPanel Grid.Row="1" Grid.Column="1">
      <TextBlock x:Name="CatDesc" DockPanel.Dock="Top" Foreground="#888" Margin="0,0,0,8" TextWrapping="Wrap"/>
      <ListView x:Name="ToolList" Background="#120000" BorderBrush="#3A0A0A" Foreground="#EEE"
                ScrollViewer.HorizontalScrollBarVisibility="Disabled">
        <ListView.View>
          <GridView>
            <GridViewColumn Header="Tool" Width="220" DisplayMemberBinding="{Binding Name}"/>
            <GridViewColumn Header="Description" Width="420" DisplayMemberBinding="{Binding Description}"/>
            <GridViewColumn Header="Kind" Width="80" DisplayMemberBinding="{Binding Kind}"/>
          </GridView>
        </ListView.View>
      </ListView>
    </DockPanel>

    <DockPanel Grid.Row="2" Grid.ColumnSpan="2" Margin="0,10,0,0">
      <StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
        <Button x:Name="BtnRun" Content="Download / Run" Width="130" Height="32" Margin="0,0,8,0"
                Background="#5A0000" Foreground="#FFF" BorderBrush="#AA2222"/>
        <Button x:Name="BtnFolder" Content="Open folder" Width="110" Height="32" Margin="0,0,8,0"
                Background="#2A1010" Foreground="#EEE" BorderBrush="#552222"/>
        <Button x:Name="BtnClear" Content="Clear tools" Width="110" Height="32" Margin="0,0,8,0"
                Background="#2A1010" Foreground="#F88" BorderBrush="#552222"/>
      </StackPanel>
      <TextBlock x:Name="StatusText" DockPanel.Dock="Right" Foreground="#9C9" VerticalAlignment="Center" Text="Ready"/>
    </DockPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$catList = $window.FindName('CatList')
$toolList = $window.FindName('ToolList')
$searchBox = $window.FindName('SearchBox')
$catDesc = $window.FindName('CatDesc')
$statusText = $window.FindName('StatusText')
$btnRun = $window.FindName('BtnRun')
$btnFolder = $window.FindName('BtnFolder')
$btnClear = $window.FindName('BtnClear')

foreach ($c in $script:Categories) {
    [void]$catList.Items.Add($c.Label)
}
if ($catList.Items.Count -gt 0) { $catList.SelectedIndex = 0 }

function Set-Status([string]$t) { $statusText.Text = $t }

function Get-SelectedCategoryKey {
    $i = $catList.SelectedIndex
    if ($i -lt 0) { return $null }
    return [string]$script:Categories[$i].Key
}

function Update-ToolList {
    $key = Get-SelectedCategoryKey
    $q = ([string]$searchBox.Text).Trim().ToLowerInvariant()
    $cat = $script:Categories | Where-Object { $_.Key -eq $key } | Select-Object -First 1
    if ($cat) { $catDesc.Text = [string]$cat.Description }

    $items = $script:AllTools | Where-Object {
        ($null -eq $key -or $_.Category -eq $key) -and (
            [string]::IsNullOrWhiteSpace($q) -or
            ([string]$_.Name).ToLowerInvariant().Contains($q) -or
            ([string]$_.Description).ToLowerInvariant().Contains($q)
        )
    }
    $toolList.ItemsSource = @($items)
}

$catList.Add_SelectionChanged({ Update-ToolList })
$searchBox.Add_TextChanged({ Update-ToolList })

$btnRun.Add_Click({
    $t = $toolList.SelectedItem
    if (-not $t) { Set-Status 'Pick a tool'; return }
    try {
        if ($t.Kind -eq 'Script') {
            Set-Status "Launching script: $($t.Name)"
            Start-ToolScript $t
            Set-Status "Started: $($t.Name)"
            return
        }
        $folder = Get-ToolFolder $t
        $existing = Find-Launchable $folder
        if ($existing) {
            Start-Process -FilePath $existing
            Set-Status "Opened: $existing"
            return
        }
        if (-not $t.Links -or $t.Links.Count -eq 0) { Set-Status 'No download link'; return }
        $launch = Save-ToolDownload $t { param($s) Set-Status $s }
        if ($launch) { Start-Process -FilePath $launch }
    } catch {
        Set-Status ("Error: {0}" -f $_.Exception.Message)
        [System.Windows.MessageBox]::Show($_.Exception.Message, $script:AppName, 'OK', 'Error') | Out-Null
    }
})

$btnFolder.Add_Click({
    Start-Process explorer.exe $script:ToolsRoot
    Set-Status $script:ToolsRoot
})

$btnClear.Add_Click({
    $r = [System.Windows.MessageBox]::Show(
        "Delete all downloaded tools under:`n$($script:ToolsRoot)",
        $script:AppName, 'YesNo', 'Warning')
    if ($r -eq 'Yes') {
        Clear-DownloadedTools
        Set-Status 'Tools folder cleared'
    }
})

Update-ToolList
Set-Status ("Catalog: {0} tools · {1}" -f $script:AllTools.Count, $script:ToolsRoot)
[void]$window.ShowDialog()
