# tocLayout.ps1 - TOC Wall Layout Manager with Tab Cycling
param(
  [Parameter(Position = 0)]
  [ValidateSet('load', 'save', 'list', 'capture', 'minimize', 'start', 'cycle', 'stop')]
  [string]$Action = 'load',
    
  [Parameter(Position = 1)]
  [string]$LayoutName = 'default',
    
  [string]$ConfigPath = "$PSScriptRoot\layouts",
    
  [switch]$Kiosk,
  [switch]$AppMode,
  [switch]$Minimized,
  [switch]$AutoCycle,
  [int]$CycleInterval = 60,
  [switch]$Background
)

# Add Windows API types for window manipulation
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Collections.Generic;
    
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
        
        [DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
        
        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
        
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        
        public const int SW_MAXIMIZE = 3;
        public const int SW_MINIMIZE = 6;
        public const int SW_RESTORE = 9;
        public const uint WM_CLOSE = 0x0010;
    }
    
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
"@

# Global variables for tracking windows and cycling state
$script:WindowProcesses = @{}
$script:CurrentUrlIndex = @{}
$script:CycleTimers = @{}
$script:IsRunning = $false

# Ensure config directory exists
if (-not (Test-Path $ConfigPath)) {
  New-Item -ItemType Directory -Path $ConfigPath | Out-Null
}

function Get-EdgeWindows {
  $edges = Get-Process msedge -ErrorAction SilentlyContinue | 
  Where-Object { $_.MainWindowTitle -ne "" }
    
  $windows = @()
  foreach ($edge in $edges) {
    $rect = New-Object RECT
    [Win32]::GetWindowRect($edge.MainWindowHandle, [ref]$rect) | Out-Null
        
    $windows += @{
      ProcessId = $edge.Id
      Handle    = $edge.MainWindowHandle.ToInt32()
      Title     = $edge.MainWindowTitle
      Position  = @{
        X      = $rect.Left
        Y      = $rect.Top
        Width  = $rect.Right - $rect.Left
        Height = $rect.Bottom - $rect.Top
      }
      Url       = ""  # Placeholder - would need UI Automation for actual URL
    }
  }
    
  return $windows
}

function Save-Layout {
  param([string]$Name)
    
  Write-Host "Capturing current window layout..." -ForegroundColor Cyan
    
  $layout = @{
    Name     = $Name
    Created  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Windows  = @()
    Settings = @{
      Kiosk          = $false
      AppMode        = $false
      MinimizeChrome = $false
      AutoCycle      = $false
      CycleInterval  = 60
      TabRotation    = @{
        Enabled  = $false
        Windows  = @()
        Interval = 60
      }
    }
  }
    
  # Capture all Edge windows
  $edgeWindows = Get-EdgeWindows
    
  if ($edgeWindows.Count -eq 0) {
    Write-Host "No Edge windows found to save." -ForegroundColor Yellow
    return
  }
    
  $windowId = 0
  foreach ($window in $edgeWindows) {
    Write-Host "  Found window: $($window.Title)" -ForegroundColor Gray
        
    # Prompt for URL since we can't easily get it without UI Automation
    $url = Read-Host "  Enter URL for this window (or press Enter to skip)"
        
    # Ask if this window should cycle through multiple URLs
    $addMore = Read-Host "  Add multiple URLs for tab cycling? (y/n)"
        
    $tabs = @()
    if ($url) {
      $tabs += @{
        Url      = $url
        Title    = $window.Title
        Duration = 0
      }
    }
        
    if ($addMore -eq 'y') {
      $layout.Settings.TabRotation.Enabled = $true
      $layout.Settings.TabRotation.Windows += $windowId
            
      while ($true) {
        $nextUrl = Read-Host "    Enter additional URL (or press Enter to finish)"
        if ([string]::IsNullOrWhiteSpace($nextUrl)) { break }
                
        $duration = Read-Host "    Duration in seconds for this URL (default: 60)"
        if ([string]::IsNullOrWhiteSpace($duration)) { $duration = "60" }
                
        $tabs += @{
          Url      = $nextUrl
          Title    = "Tab"
          Duration = [int]$duration
        }
      }
    }
        
    $layout.Windows += @{
      Id               = $windowId
      Name             = "Monitor $windowId"
      Position         = $window.Position
      Tabs             = $tabs
      IframeCompatible = $false
      BrowserArgs      = @()
    }
        
    $windowId++
  }
    
  # Save to JSON
  $filePath = Join-Path $ConfigPath "$Name.json"
  $layout | ConvertTo-Json -Depth 10 | Set-Content $filePath
    
  Write-Host "Layout saved to: $filePath" -ForegroundColor Green
  Write-Host "Saved $($layout.Windows.Count) windows" -ForegroundColor Green
}

function Load-Layout {
  param(
    [string]$Name,
    [bool]$StartCycling = $false
  )
    
  $filePath = Join-Path $ConfigPath "$Name.json"
    
  if (-not (Test-Path $filePath)) {
    Write-Host "Layout file not found: $filePath" -ForegroundColor Red
    return $null
  }
    
  Write-Host "Loading layout: $Name" -ForegroundColor Cyan
  $layout = Get-Content $filePath | ConvertFrom-Json
    
  # Close existing Edge windows if requested
  if (-not $StartCycling) {
    $closeExisting = Read-Host "Close existing Edge windows? (y/n)"
    if ($closeExisting -eq 'y') {
      Stop-EdgeWindows
      Start-Sleep -Seconds 2
    }
  }
    
  # Launch windows
  foreach ($window in $layout.Windows) {
    if ($window.Tabs.Count -eq 0) {
      Write-Host "  Skipping window $($window.Id) - no URLs defined" -ForegroundColor Yellow
      continue
    }
        
    Write-Host "  Launching: $($window.Name)" -ForegroundColor Gray
        
    # Build Edge arguments
    $edgeArgs = @()
    $url = $window.Tabs[0].Url
        
    # Window mode arguments
    if ($Kiosk -or $layout.Settings.Kiosk) {
      $edgeArgs += "--kiosk"
      $edgeArgs += $url
    }
    elseif ($AppMode -or $layout.Settings.AppMode) {
      $edgeArgs += "--app=$url"
    }
    else {
      $edgeArgs += "--new-window"
      $edgeArgs += $url
            
      # Minimize UI chrome
      if ($Minimized -or $layout.Settings.MinimizeChrome) {
        $edgeArgs += "--hide-tab-strip"
      }
    }
        
    # Add user data dir for separate profiles
    $edgeArgs += "--user-data-dir=$env:TEMP\EdgeProfile$($window.Id)"
        
    # Add any custom browser args
    if ($window.BrowserArgs) {
      $edgeArgs += $window.BrowserArgs
    }
        
    # Start Edge
    $process = Start-Process msedge -ArgumentList $edgeArgs -PassThru
        
    # Store process info
    $script:WindowProcesses[$window.Id] = $process
    $script:CurrentUrlIndex[$window.Id] = 0
        
    # Wait for window to be ready
    Start-Sleep -Milliseconds 1500
        
    # Position window
    if ($window.Position) {
      $pos = $window.Position
      [Win32]::MoveWindow(
        $process.MainWindowHandle, 
        $pos.X, 
        $pos.Y, 
        $pos.Width, 
        $pos.Height, 
        $true
      ) | Out-Null
            
      Write-Host "    Positioned at: $($pos.X),$($pos.Y) Size: $($pos.Width)x$($pos.Height)" -ForegroundColor Gray
    }
  }
    
  Write-Host "Layout loaded successfully!" -ForegroundColor Green
  return $layout
}

function Start-Cycling {
  param([string]$Name)
    
  Write-Host "`nStarting TOC Wall with auto-cycling..." -ForegroundColor Cyan
    
  # Load the layout
  $layout = Load-Layout -Name $Name -StartCycling $true
  if (-not $layout) { return }
    
  $script:IsRunning = $true
    
  # Check if any windows need cycling
  $windowsWithCycling = $layout.Windows | Where-Object { $_.Tabs.Count -gt 1 }
    
  if ($windowsWithCycling.Count -eq 0) {
    Write-Host "No windows configured for tab cycling." -ForegroundColor Yellow
    return
  }
    
  Write-Host "`nTab cycling active for $($windowsWithCycling.Count) windows" -ForegroundColor Green
  Write-Host "Press Ctrl+C to stop cycling..." -ForegroundColor Yellow
    
  # Set up Ctrl+C handler
  [Console]::TreatControlCAsInput = $false
  $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $script:IsRunning = $false
  }
    
  try {
    # Main cycling loop
    while ($script:IsRunning) {
      foreach ($window in $windowsWithCycling) {
        # Check if rotation is enabled for this window
        $shouldRotate = $false
                
        if ($AutoCycle -or $layout.Settings.AutoCycle) {
          $shouldRotate = $true
        }
        elseif ($layout.Settings.TabRotation.Enabled) {
          if ($layout.Settings.TabRotation.Windows -contains $window.Id) {
            $shouldRotate = $true
          }
        }
                
        if ($shouldRotate) {
          # Get current and next URL
          $currentIndex = $script:CurrentUrlIndex[$window.Id]
                    
          # Check if it's time to rotate based on duration
          $currentTab = $window.Tabs[$currentIndex]
          $duration = if ($currentTab.Duration -gt 0) { $currentTab.Duration } else { $CycleInterval }
                    
          if (-not $script:CycleTimers.ContainsKey($window.Id)) {
            $script:CycleTimers[$window.Id] = [DateTime]::Now
          }
                    
          $elapsed = ([DateTime]::Now - $script:CycleTimers[$window.Id]).TotalSeconds
                    
          if ($elapsed -ge $duration) {
            # Time to rotate
            $nextIndex = ($currentIndex + 1) % $window.Tabs.Count
            $nextUrl = $window.Tabs[$nextIndex].Url
                        
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Window $($window.Id): Rotating to $($window.Tabs[$nextIndex].Title)" -ForegroundColor Cyan
                        
            # Close current window
            $process = $script:WindowProcesses[$window.Id]
            if ($process -and -not $process.HasExited) {
              $process.Kill()
              Start-Sleep -Milliseconds 500
            }
                        
            # Launch new window with next URL
            $edgeArgs = @()
                        
            if ($Kiosk -or $layout.Settings.Kiosk) {
              $edgeArgs += "--kiosk", $nextUrl
            }
            elseif ($AppMode -or $layout.Settings.AppMode) {
              $edgeArgs += "--app=$nextUrl"
            }
            else {
              $edgeArgs += "--new-window", $nextUrl
            }
                        
            $edgeArgs += "--user-data-dir=$env:TEMP\EdgeProfile$($window.Id)"
                        
            $newProcess = Start-Process msedge -ArgumentList $edgeArgs -PassThru
            Start-Sleep -Milliseconds 1000
                        
            # Reposition window
            if ($window.Position) {
              $pos = $window.Position
              [Win32]::MoveWindow(
                $newProcess.MainWindowHandle,
                $pos.X,
                $pos.Y,
                $pos.Width,
                $pos.Height,
                $true
              ) | Out-Null
            }
                        
            # Update tracking
            $script:WindowProcesses[$window.Id] = $newProcess
            $script:CurrentUrlIndex[$window.Id] = $nextIndex
            $script:CycleTimers[$window.Id] = [DateTime]::Now
          }
        }
      }
            
      # Small sleep to prevent CPU spinning
      Start-Sleep -Seconds 1
            
      # Check for Ctrl+C
      if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::C -and $key.Modifiers -eq [ConsoleModifiers]::Control) {
          $script:IsRunning = $false
          Write-Host "`nStopping cycle..." -ForegroundColor Yellow
          break
        }
      }
    }
  }
  finally {
    Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
    Write-Host "Cycling stopped." -ForegroundColor Green
  }
}

function Stop-EdgeWindows {
  Write-Host "Closing all Edge windows..." -ForegroundColor Yellow
    
  # Close tracked windows
  foreach ($windowId in $script:WindowProcesses.Keys) {
    $process = $script:WindowProcesses[$windowId]
    if ($process -and -not $process.HasExited) {
      $process.Kill()
    }
  }
    
  # Also close any other Edge windows
  Get-Process msedge -ErrorAction SilentlyContinue | 
  Where-Object { $_.MainWindowTitle -ne "" } | 
  Stop-Process -Force -ErrorAction SilentlyContinue
    
  $script:WindowProcesses.Clear()
  $script:CurrentUrlIndex.Clear()
  $script:CycleTimers.Clear()
    
  Write-Host "All Edge windows closed." -ForegroundColor Green
}

function List-Layouts {
  Write-Host "`nAvailable layouts:" -ForegroundColor Cyan
  $layouts = Get-ChildItem -Path $ConfigPath -Filter "*.json" -ErrorAction SilentlyContinue
    
  if ($layouts.Count -eq 0) {
    Write-Host "  No layouts found in $ConfigPath" -ForegroundColor Yellow
  }
  else {
    foreach ($layout in $layouts) {
      $content = Get-Content $layout.FullName | ConvertFrom-Json
      Write-Host "  - $($layout.BaseName)" -ForegroundColor Green
      Write-Host "    Created: $($content.Created)" -ForegroundColor Gray
      Write-Host "    Windows: $($content.Windows.Count)" -ForegroundColor Gray
            
      $cyclingWindows = $content.Windows | Where-Object { $_.Tabs.Count -gt 1 }
      if ($cyclingWindows.Count -gt 0) {
        Write-Host "    Cycling: $($cyclingWindows.Count) windows with rotation" -ForegroundColor Gray
      }
    }
  }
}

function Show-Help {
  Write-Host "`nTOC Wall Layout Manager" -ForegroundColor Cyan
  Write-Host "========================" -ForegroundColor Cyan
  Write-Host "`nUsage: .\tocLayout.ps1 [action] [layout-name] [options]" -ForegroundColor Yellow
    
  Write-Host "`nActions:" -ForegroundColor Green
  Write-Host "  load       - Load a saved layout"
  Write-Host "  save       - Save current window configuration"
  Write-Host "  start      - Load layout and start tab cycling"
  Write-Host "  cycle      - Alias for 'start' with cycling"
  Write-Host "  stop       - Stop all Edge windows"
  Write-Host "  list       - List available layouts"
  Write-Host "  capture    - Capture current state (limited URL detection)"
    
  Write-Host "`nOptions:" -ForegroundColor Green
  Write-Host "  -Kiosk          - Launch in kiosk mode (F11 to exit)"
  Write-Host "  -AppMode        - Launch in app mode (minimal chrome)"
  Write-Host "  -Minimized      - Hide tab strip (limited effectiveness)"
  Write-Host "  -AutoCycle      - Enable automatic tab cycling"
  Write-Host "  -CycleInterval  - Default cycle interval in seconds (default: 60)"
  Write-Host "  -ConfigPath     - Path to layout files (default: .\layouts)"
    
  Write-Host "`nExamples:" -ForegroundColor Cyan
  Write-Host "  .\tocLayout.ps1 save monitoring" -ForegroundColor Gray
  Write-Host "  .\tocLayout.ps1 load monitoring" -ForegroundColor Gray
  Write-Host "  .\tocLayout.ps1 start monitoring -AutoCycle" -ForegroundColor Gray
  Write-Host "  .\tocLayout.ps1 start monitoring -Kiosk -CycleInterval 30" -ForegroundColor Gray
  Write-Host "  .\tocLayout.ps1 stop" -ForegroundColor Gray
  Write-Host "  .\tocLayout.ps1 list" -ForegroundColor Gray
}

# Main execution
switch ($Action) {
  'save' {
    Save-Layout -Name $LayoutName
  }
  'load' {
    Load-Layout -Name $LayoutName
  }
  'start' {
    Start-Cycling -Name $LayoutName
  }
  'cycle' {
    $AutoCycle = $true
    Start-Cycling -Name $LayoutName
  }
  'stop' {
    Stop-EdgeWindows
  }
  'capture' {
    Write-Host "Capture feature requires UI Automation for accurate URL detection." -ForegroundColor Yellow
    Write-Host "Using 'save' command instead for manual URL entry..." -ForegroundColor Yellow
    Save-Layout -Name $LayoutName
  }
  'list' {
    List-Layouts
  }
  default {
    Show-Help
    List-Layouts
  }
}