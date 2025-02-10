# Magic Toggle

Magic Toggle is a macOS menu bar application that automatically manages Apple Magic Device connections based on external display status.

## Features

- Automatically connects saved devices when an external display is connected
- Automatically disconnects devices when external displays are disconnected
- Manages multiple Bluetooth devices simultaneously
- Shows real-time device connection status
- Preserves device history and settings between app launches
- New devices are automatically saved for convenience
- Supports batch operations for all saved devices

## Requirements

- macOS 13.0 or later
- Apple Magic devices (Magic Mouse, Magic Keyboard, etc.)
- External display support
- [blueutil](https://github.com/toy/blueutil) command-line tool

## Installation

1. Install blueutil:

```bash
brew install blueutil
```

2. Download Magic Toggle.app
3. Move to your Applications folder
4. Launch Magic Toggle
5. Grant necessary permissions when prompted (Bluetooth, Accessibility)

## Usage

### Menu Bar

- Single monitor icon: No external display connected
- Dual monitor icon: External display connected
- Click to access:
  - Devices window
  - About window
  - Quit option

### Devices Window

- Device Status Indicators:
  - Green: Connected
  - Red: Disconnected but paired
  - Gray: Not paired
  - Yellow: Pairing in progress
  - Blue: Connecting
  - Orange: Unpairing
- Features:
  - Toggle switch to save/unsave devices
  - "Pair Saved"/"Unpair Saved" button for batch operations
  - "Show only saved devices" filter (on by default)
  - Refresh button to manually update device list
  - Remove button (trash icon) for unpaired devices
  - Last seen times for each device

### Automatic Operation

- Saved devices automatically connect when an external display is detected
- Devices automatically disconnect when external display is removed
- Device list refreshes automatically every 5 seconds
- New devices are saved by default for convenience

## Building from Source

1. Clone the repository
2. Open `Magic Toggle.xcodeproj` in Xcode
3. Build and run the project

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.

## Author

Created by Ruslan Butov © 2025
