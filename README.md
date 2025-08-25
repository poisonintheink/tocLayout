# TOC Wall Layout Manager

## Overview

The TOC Wall Layout Manager is a PowerShell-based solution for managing multi-monitor display walls, typically used in Technical Operations Centers (TOC), Network Operations Centers (NOC), Security Operations Centers (SOC), and similar command center environments. This tool enables operators to automatically position, manage, and cycle through Microsoft Edge browser windows across multiple monitors, creating an effective dashboard display system for monitoring various web-based applications, metrics, and information feeds.

## Table of Contents

1. [Key Features](#key-features)
2. [System Requirements](#system-requirements)
3. [Installation](#installation)
4. [Core Concepts](#core-concepts)
5. [Usage Guide](#usage-guide)
6. [Command Reference](#command-reference)
7. [Configuration Files](#configuration-files)
8. [Code Architecture](#code-architecture)
9. [Advanced Features](#advanced-features)
10. [Troubleshooting](#troubleshooting)
11. [Security Considerations](#security-considerations)
12. [Best Practices](#best-practices)

## Key Features

### Window Management
- **Automated Window Positioning**: Precisely place browser windows at specific coordinates with defined dimensions
- **Multi-Monitor Support**: Span windows across multiple displays in extended desktop configurations
- **Profile Isolation**: Each window runs with its own browser profile to prevent session conflicts
- **Batch Operations**: Launch, position, and close multiple windows simultaneously

### Tab Cycling and Rotation
- **Automatic URL Rotation**: Cycle through multiple URLs in each window at configurable intervals
- **Per-URL Duration**: Set individual display times for each URL in the rotation
- **Synchronized Operations**: Manage multiple rotating windows simultaneously
- **Smart Refresh**: Windows are recreated during rotation to ensure fresh content loads

### Display Modes
- **Kiosk Mode**: Full-screen display with minimal user interface elements
- **App Mode**: Application-style windows with reduced browser chrome
- **Standard Mode**: Regular browser windows with optional UI minimization
- **Minimized Chrome**: Hide unnecessary browser UI elements for maximum content visibility

### Layout Management
- **Save Configurations**: Capture current window arrangements for later use
- **Load Profiles**: Instantly restore saved display configurations
- **JSON Storage**: Human-readable configuration files for easy editing and version control
- **Multiple Layouts**: Maintain different configurations for various operational scenarios

## System Requirements

### Minimum Requirements
- **Operating System**: Windows 10 version 1903 or later, Windows 11
- **PowerShell**: Version 5.1 or later (Windows PowerShell) or PowerShell Core 7+
- **Browser**: Microsoft Edge (Chromium-based) version 79 or later
- **Memory**: 4GB RAM minimum (8GB+ recommended for multiple windows)
- **Display**: Single or multiple monitors in extended desktop mode

### Recommended Configuration
- **Operating System**: Windows 11 Pro or Enterprise
- **PowerShell**: PowerShell 7.3 or later
- **Memory**: 16GB RAM or more for smooth operation with 10+ windows
- **Graphics**: Dedicated graphics card for better performance with multiple displays
- **Network**: Stable internet connection for loading external dashboards

## Installation

### Step 1: Download the Script
```powershell
# Create a directory for the TOC Wall Manager
New-Item -ItemType Directory -Path "C:\TOCWall" -Force

# Download or copy tocLayout.ps1 to this directory
# The script will automatically create a 'layouts' subdirectory for configurations
```

### Step 2: Set Execution Policy
```powershell
# Allow script execution (requires administrator privileges)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for a specific session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Step 3: Verify Installation
```powershell
# Navigate to the script directory
cd C:\TOCWall

# Run the help command to verify installation
.\tocLayout.ps1
```

## Core Concepts

### Layouts
A layout represents a complete display wall configuration, including:
- Window positions and dimensions
- URLs to display in each window
- Display mode preferences (kiosk, app, standard)
- Tab rotation settings
- Browser launch parameters

### Windows
Each window in a layout represents a single browser instance with:
- **Position**: X/Y coordinates and width/height in pixels
- **Tabs**: One or more URLs to display/cycle
- **Profile**: Isolated browser profile for independent sessions
- **Settings**: Individual display mode and behavior options

### Tab Cycling
The automatic rotation feature allows each window to:
- Display multiple URLs in sequence
- Configure individual display duration per URL
- Maintain synchronized timing across windows
- Refresh content by recreating the window on each cycle

### Configuration Storage
Layouts are stored as JSON files containing:
- Human-readable configuration data
- Timestamp information for tracking versions
- Nested structure for complex multi-window setups
- Extensible format for future enhancements

## Usage Guide

### Basic Workflow

#### 1. Initial Setup - Creating Your First Layout
```powershell
# Manually arrange Edge windows on your monitors as desired
# Open Edge and position windows where you want them

# Save the current arrangement
.\tocLayout.ps1 save MyFirstLayout

# The script will:
# - Detect all open Edge windows
# - Capture their positions
# - Prompt you for URLs to associate with each window
# - Ask if you want to add multiple URLs for cycling
# - Save the configuration to layouts\MyFirstLayout.json
```

#### 2. Loading a Saved Layout
```powershell
# Load a previously saved layout
.\tocLayout.ps1 load MyFirstLayout

# The script will:
# - Read the configuration file
# - Ask if you want to close existing windows
# - Launch new Edge windows
# - Position them according to the saved layout
# - Load the specified URLs
```

#### 3. Starting with Auto-Cycling
```powershell
# Start the layout with automatic tab cycling enabled
.\tocLayout.ps1 start MyFirstLayout -AutoCycle -CycleInterval 30

# This will:
# - Load the layout
# - Begin rotating through URLs in windows with multiple tabs
# - Change URLs every 30 seconds (or per-URL duration if specified)
# - Continue until you press Ctrl+C
```

### Advanced Scenarios

#### Multi-Monitor Dashboard Setup
```powershell
# Create a comprehensive monitoring dashboard
# Arrange windows across 3 monitors for different systems

# Monitor 1: Network monitoring
# Monitor 2: Security dashboards  
# Monitor 3: Application metrics

.\tocLayout.ps1 save NetworkOpsCenter

# When prompted, add URLs like:
# Window 1: Network monitoring tools (multiple URLs with 60-second rotation)
# Window 2: Security dashboard (single URL, no rotation)
# Window 3: Application metrics (multiple URLs with 120-second rotation)
```

#### Kiosk Mode for Public Displays
```powershell
# Launch in full-screen kiosk mode for public information displays
.\tocLayout.ps1 load PublicDisplay -Kiosk

# All windows will launch in full-screen mode
# Press F11 to exit kiosk mode if needed
```

#### Incident Response Configuration
```powershell
# Quick-launch preset for incident response scenarios
.\tocLayout.ps1 start IncidentResponse -AutoCycle -CycleInterval 15

# Rapidly cycles through critical monitoring pages
# Short intervals for maximum visibility during incidents
```

## Command Reference

### Actions

#### `save [layout-name]`
Captures the current Edge window configuration and saves it as a named layout.

**Interactive Process:**
1. Detects all open Edge windows
2. Records their positions and dimensions
3. Prompts for URL for each window
4. Optionally configures multi-URL rotation
5. Saves configuration to JSON file

**Example:**
```powershell
.\tocLayout.ps1 save DailyMonitoring
```

#### `load [layout-name]`
Loads a saved layout and positions windows accordingly.

**Options:**
- Optionally closes existing Edge windows
- Launches windows with saved URLs
- Applies saved position and size
- Uses isolated browser profiles

**Example:**
```powershell
.\tocLayout.ps1 load DailyMonitoring
```

#### `start [layout-name]`
Loads a layout and begins automatic tab cycling for configured windows.

**Features:**
- Combines load and cycle functionality
- Enables rotation for multi-tab windows
- Continues until manually stopped
- Maintains timing synchronization

**Example:**
```powershell
.\tocLayout.ps1 start DailyMonitoring -AutoCycle
```

#### `cycle [layout-name]`
Alias for `start` with auto-cycling enabled by default.

**Example:**
```powershell
.\tocLayout.ps1 cycle DailyMonitoring -CycleInterval 45
```

#### `stop`
Immediately closes all Edge windows managed by the script.

**Behavior:**
- Terminates all tracked window processes
- Clears internal tracking state
- Also closes untracked Edge windows
- Cleans up temporary browser profiles

**Example:**
```powershell
.\tocLayout.ps1 stop
```

#### `list`
Displays all available saved layouts with details.

**Information Shown:**
- Layout names
- Creation timestamps
- Number of windows
- Cycling configuration

**Example:**
```powershell
.\tocLayout.ps1 list
```

#### `capture [layout-name]`
Attempts to capture existing window state (limited functionality).

**Note:** Due to browser security, URL detection is limited. The script will fall back to manual URL entry.

**Example:**
```powershell
.\tocLayout.ps1 capture CurrentState
```

### Parameters

#### `-Kiosk`
Launches all windows in full-screen kiosk mode.

**Characteristics:**
- No browser UI visible
- F11 key exits kiosk mode
- Ideal for public displays
- Prevents user interaction

**Example:**
```powershell
.\tocLayout.ps1 load PublicInfo -Kiosk
```

#### `-AppMode`
Launches windows as standalone applications.

**Characteristics:**
- Minimal browser chrome
- No tab bar or navigation buttons
- Window appears as dedicated application
- Cleaner visual presentation

**Example:**
```powershell
.\tocLayout.ps1 load Dashboard -AppMode
```

#### `-Minimized`
Attempts to hide browser UI elements.

**Note:** Effectiveness varies by Edge version and Windows configuration.

**Example:**
```powershell
.\tocLayout.ps1 load Monitoring -Minimized
```

#### `-AutoCycle`
Enables automatic tab rotation for multi-URL windows.

**Behavior:**
- Activates cycling for configured windows
- Uses default or specified intervals
- Continues until stopped
- Refreshes content on each cycle

**Example:**
```powershell
.\tocLayout.ps1 start Operations -AutoCycle
```

#### `-CycleInterval [seconds]`
Sets the default rotation interval in seconds.

**Default:** 60 seconds

**Note:** Individual URLs can override this with specific durations.

**Example:**
```powershell
.\tocLayout.ps1 start Monitoring -AutoCycle -CycleInterval 120
```

#### `-ConfigPath [path]`
Specifies alternate location for layout files.

**Default:** `.\layouts`

**Use Cases:**
- Network storage for shared configurations
- Version control integration
- Backup locations

**Example:**
```powershell
.\tocLayout.ps1 load SharedLayout -ConfigPath "\\server\configs"
```

## Configuration Files

### JSON Structure

Layout files use the following JSON structure:

```json
{
  "Name": "LayoutName",
  "Created": "2025-01-15 10:30:00",
  "Windows": [
    {
      "Id": 0,
      "Name": "Monitor 0",
      "Position": {
        "X": 0,
        "Y": 0,
        "Width": 1920,
        "Height": 1080
      },
      "Tabs": [
        {
          "Url": "https://dashboard.example.com",
          "Title": "Main Dashboard",
          "Duration": 60
        },
        {
          "Url": "https://metrics.example.com",
          "Title": "Metrics",
          "Duration": 45
        }
      ],
      "IframeCompatible": false,
      "BrowserArgs": ["--disable-features=TranslateUI"]
    }
  ],
  "Settings": {
    "Kiosk": false,
    "AppMode": false,
    "MinimizeChrome": true,
    "AutoCycle": true,
    "CycleInterval": 60,
    "TabRotation": {
      "Enabled": true,
      "Windows": [0],
      "Interval": 60
    }
  }
}
```

### Configuration Elements

#### Window Position
- **X, Y**: Top-left corner coordinates in pixels
- **Width, Height**: Window dimensions in pixels
- Coordinates are relative to primary display origin

#### Tabs Array
- **Url**: Full URL to display
- **Title**: Descriptive name for logging
- **Duration**: Display time in seconds (0 uses default)

#### Browser Arguments
Additional command-line arguments passed to Edge:
- `--disable-features=TranslateUI`: Disable translation prompts
- `--disable-infobars`: Hide information bars
- `--disable-session-crashed-bubble`: Suppress crash notifications

## Code Architecture

### Core Components

#### 1. Windows API Integration
The script uses Windows User32.dll APIs through P/Invoke:
- **MoveWindow**: Positions and sizes windows
- **GetWindowRect**: Retrieves current window dimensions
- **ShowWindow**: Controls window state
- **SetForegroundWindow**: Brings windows to front

#### 2. Process Management
PowerShell cmdlets handle browser lifecycle:
- **Start-Process**: Launches Edge with specific arguments
- **Get-Process**: Finds existing Edge windows
- **Stop-Process**: Terminates browser instances

#### 3. State Tracking
Global script variables maintain operational state:
- **$script:WindowProcesses**: Maps window IDs to process objects
- **$script:CurrentUrlIndex**: Tracks rotation position
- **$script:CycleTimers**: Manages timing for each window
- **$script:IsRunning**: Controls cycling loop

#### 4. Configuration Management
JSON serialization handles persistent storage:
- **ConvertTo-Json**: Serializes layout objects
- **ConvertFrom-Json**: Deserializes saved configurations
- **Depth parameter**: Ensures nested objects are fully captured

### Function Descriptions

#### `Get-EdgeWindows`
Enumerates all Edge windows with visible titles and captures their current positions.

**Returns:** Array of window information objects

#### `Save-Layout`
Interactive function that captures current window state and creates a layout configuration.

**Process Flow:**
1. Enumerate windows
2. Prompt for URLs
3. Configure rotation options
4. Serialize to JSON

#### `Load-Layout`
Reads a layout file and launches/positions windows accordingly.

**Process Flow:**
1. Parse JSON configuration
2. Optional cleanup of existing windows
3. Launch new windows with arguments
4. Apply positioning
5. Store process references

#### `Start-Cycling`
Main loop for automatic tab rotation functionality.

**Process Flow:**
1. Load layout
2. Initialize timers
3. Monitor elapsed time
4. Rotate URLs when intervals expire
5. Handle interruption signals

#### `Stop-EdgeWindows`
Cleanup function that terminates all managed browser instances.

**Operations:**
1. Kill tracked processes
2. Find and close untracked Edge windows
3. Clear state variables
4. Clean temporary profiles

## Advanced Features

### Browser Profile Isolation

Each window uses an independent browser profile:
```powershell
--user-data-dir=$env:TEMP\EdgeProfile$($window.Id)
```

**Benefits:**
- Separate cookie stores
- Independent sessions
- No authentication conflicts
- Isolated cache and history

### Dynamic URL Rotation

The rotation system supports:
- **Variable Intervals**: Each URL can have its own display duration
- **Window Recreation**: Fresh page loads on each rotation
- **State Persistence**: Rotation continues from last position
- **Synchronized Timing**: Multiple windows rotate independently

### Graceful Interruption

The script handles Ctrl+C gracefully:
- Registers PowerShell exit events
- Monitors keyboard input
- Cleans up resources
- Provides status feedback

## Troubleshooting

### Common Issues and Solutions

#### Windows Don't Position Correctly
**Symptom:** Windows appear but aren't in saved positions

**Solutions:**
- Ensure windows are fully loaded before positioning (increase sleep time)
- Check if coordinates are within display boundaries
- Verify multiple monitors are in extended mode
- Run script with administrator privileges

#### URLs Don't Load
**Symptom:** Windows open but remain blank or show error pages

**Solutions:**
- Verify URLs are accessible from the machine
- Check network connectivity and proxy settings
- Ensure URLs include protocol (https://)
- Test URLs manually in Edge first

#### Cycling Stops Unexpectedly
**Symptom:** Rotation halts without user intervention

**Solutions:**
- Check system memory usage
- Verify no other scripts are terminating Edge
- Review Windows Event Log for crashes
- Increase cycle interval to reduce load

#### Kiosk Mode Won't Exit
**Symptom:** F11 doesn't exit full-screen mode

**Solutions:**
- Use Alt+F4 to close window
- Press Windows key to access taskbar
- Use Task Manager to end Edge process
- Run `.\tocLayout.ps1 stop` from another PowerShell window

### Diagnostic Commands

```powershell
# Check if Edge processes are running
Get-Process msedge | Select-Object Id, MainWindowTitle, StartTime

# Verify script location and permissions
Get-ChildItem C:\TOCWall -Recurse | Select-Object Name, LastWriteTime

# Test Windows API availability
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Test {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
    }
"@
[Test]::GetForegroundWindow()

# Check PowerShell version
$PSVersionTable.PSVersion
```

## Security Considerations

### Browser Security
- **Profile Isolation**: Each window runs in its own profile sandbox
- **No Credential Storage**: Temporary profiles don't persist authentication
- **HTTPS Enforcement**: Always use secure connections for sensitive dashboards
- **Content Security**: Be aware of mixed content warnings

### Script Security
- **Execution Policy**: Use appropriate PowerShell execution policies
- **Path Validation**: Script validates configuration paths
- **No Elevation Required**: Runs with standard user privileges
- **Input Sanitization**: User inputs are validated before use

### Operational Security
- **Access Control**: Restrict access to layout configuration files
- **Sensitive URLs**: Don't store credentials in URLs
- **Network Isolation**: Consider network segmentation for TOC displays
- **Regular Updates**: Keep Edge and Windows updated

### Best Practices for Secure Deployment
1. Store layout files in protected directories
2. Use Windows authentication for dashboard access
3. Implement screen timeout policies
4. Regular audit of displayed content
5. Separate profiles for different security levels

## Best Practices

### Layout Design
1. **Group Related Content**: Keep associated dashboards on the same monitor
2. **Prioritize Critical Information**: Place most important feeds at eye level
3. **Balance Load**: Distribute resource-intensive dashboards across windows
4. **Consider Viewing Distance**: Size windows appropriately for operator distance
5. **Plan for Failures**: Have backup layouts for degraded scenarios

### Performance Optimization
1. **Limit Concurrent Windows**: Start with fewer windows and scale up
2. **Stagger Rotation Intervals**: Avoid all windows rotating simultaneously
3. **Use Appropriate Intervals**: Balance freshness with system load
4. **Monitor Resource Usage**: Track CPU and memory consumption
5. **Regular Restarts**: Schedule periodic full restarts to clear memory

### Operational Guidelines
1. **Document Layouts**: Maintain descriptions of what each layout monitors
2. **Version Control**: Track layout changes in source control
3. **Test Changes**: Verify modifications in test environment first
4. **Train Operators**: Ensure staff know how to load emergency layouts
5. **Create Runbooks**: Document procedures for common scenarios

### Maintenance Procedures
1. **Weekly Tasks**:
   - Review and update URLs for deprecated dashboards
   - Check for browser updates
   - Verify all layouts load correctly

2. **Monthly Tasks**:
   - Clean temporary browser profiles
   - Archive unused layouts
   - Review performance metrics
   - Update documentation

3. **Quarterly Tasks**:
   - Reassess layout effectiveness
   - Gather operator feedback
   - Optimize rotation intervals
   - Security review of displayed content

## Support and Contribution

### Getting Help
- Review this documentation thoroughly
- Check the Troubleshooting section
- Test with simplified configurations
- Isolate issues to specific windows or URLs

### Contributing Improvements
When sharing modifications:
1. Document new features clearly
2. Maintain backward compatibility
3. Test across multiple Windows versions
4. Include example configurations
5. Update relevant documentation

### Future Enhancements
Potential areas for expansion:
- Chrome browser support
- Web-based configuration interface
- Remote management capabilities
- Performance metrics collection
- Integration with monitoring APIs
- Automated health checks
- Mobile device support for configuration

## Conclusion

The TOC Wall Layout Manager provides a robust solution for managing multi-monitor display walls in operational environments. By automating the positioning and cycling of web-based dashboards, it enables operators to maintain situational awareness across multiple systems and data sources. With proper configuration and maintenance, this tool can significantly enhance the effectiveness of any technical operations center.

Remember to regularly review and update your layouts as operational requirements evolve, and always test changes before deploying them in production environments.