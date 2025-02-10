# Magic Toggle

Magic Toggle is a macOS application that helps manage your Apple Magic devices across multiple Macs. It automatically connects your saved devices when an external display is connected, and disconnects them when the display is unplugged. This makes it easy to switch your Magic Mouse, Keyboard and other devices between different Mac computers while maintaining a streamlined workflow based on your monitor setup.

## Features

- Automatic Device Management

  - Connects saved devices when external display is connected
  - Disconnects devices when external display is removed
  - Manages multiple devices simultaneously
  - Real-time connection status monitoring
  - Automatic 5-second refresh interval

- Device Management

  - Save/unsave devices with toggle switches
  - Batch operations for all saved devices
  - Device history preservation between launches
  - New devices are automatically saved
  - Last seen timestamps for each device

- Status Indicators
  - Green: Connected
  - Red: Disconnected but paired
  - Gray: Not paired
  - Yellow: Pairing in progress
  - Blue: Connecting
  - Orange: Unpairing

## Requirements

- macOS 13.0 or later
- Apple Magic devices (Magic Mouse, Magic Keyboard, etc.)
- External display support
- Homebrew package manager
- blueutil command-line tool

## Installation

1. Install Homebrew (if not already installed):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install blueutil:

```bash
brew install blueutil
```

3. Download and install Magic Toggle:
   - Download Magic Toggle.app
   - Move to Applications folder
   - Launch Magic Toggle
   - Grant requested permissions (Bluetooth, Accessibility)

## Usage

### Menu Bar

- Monitor icon indicates display status:
  - Single monitor: No external display
  - Dual monitors: External display connected
- Click for quick access to:
  - Devices window
  - About window
  - Quit option

### Devices Window

- Device List

  - Shows all discovered Apple peripherals
  - Status indicators for each device
  - Last seen timestamps
  - Save/unsave toggles
  - Remove option for unpaired devices

- Controls
  - "Pair Saved"/"Unpair Saved" for batch operations
  - "Show only saved devices" filter (default: on)
  - Manual refresh button

## Building from Source

1. Clone the repository
2. Install dependencies:

```bash
brew install blueutil
```

3. Open `Magic Toggle.xcodeproj` in Xcode
4. Build and run

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.

## Author

Created by Ruslan Butov © 2025
