# Better Canisters Mod

Customize the capacity and transfer rate of canisters and oxygen tanks in Astroneer.

## Version
**v2.2.0-polling** - Updated for Atenfyr's UE4SS v3.0.1 Fork

## 🚨 Critical Requirements

**You MUST use Atenfyr's specific UE4SS Fork for this mod to work!**
- **Download**: [Atenfyr's RE-UE4SS v3.0.1](https://github.com/atenfyr/RE-UE4SS/releases/download/latest/UE4SS_v3.0.1-2-12c6627.zip)
- **Why**: Standard releases (v2.5.2 or v3.0) do not work with Astroneer's engine modifications.
- **Loader**: Ensure `dwmapi.dll` is placed next to `Astro-Win64-Shipping.exe`.
- **Mod Location**: Unzip mod to `Astro/Binaries/Win64/ue4ss/Mods/BetterCanistersMod`.

## Installation

1.  **Install UE4SS**:
    - Download the zip linked above.
    - Extract contents to `Astro/Binaries/Win64/`.
    - Verify `dwmapi.dll` is in the same folder as the game exe.
    - Verify `ue4ss/` folder exists.
2.  **Install Mod**:
    - Copy `BetterCanistersMod` folder into `ue4ss/Mods/`.
3.  **Configure**:
    - Check `options.lua` in the mod folder to customize values.
4.  **Launch Game**:
    - The mod will automatically load and apply changes.

## Usage and Configuration

Better Canisters uses a single configuration file: **`options.lua`**.

### Applying Changes
- **Existing canisters**: Automatically updated EVERY time you load a save (Enforced consistency).
- **New canisters**: Automatically detected within 3 seconds of crafting/unpacking (via Polling).
- **Edit values**: Edit `options.lua` and restart game or reload save to apply new values immediately.

## Default Game Values
(See `options.lua` for full list of adjustable values)

| Name | Capacity | Transfer Rate |
|------|----------|---------------|
| Medium Resource | 32 | 1.0 |
| Large Resource | 400 | 1.0 |
| Large Gas | 2000 | 5.0 |

## Troubleshooting

### Canisters not updating?
1.  **Check UE4SS Version**: If you are using standard v2.5.2 or v3.0 Experimental, **IT WILL NOT WORK**. You must use Atenfyr's fork (see top of file).
2.  **Check Logs**: Open `ue4ss/UE4SS.log`. Search for `[BetterCanistersMod]`.
    - You should see "Starting Polling Loop...".
    - You should see "Enforcing Canister Capacity settings..." on load.
3.  **Polling**: This mod uses specific polling logic to detect new items. If items aren't detected, check if `PollForNewCanisters` is crashing in the log.

### Game crashes on startup?
- Set `bUseUObjectArrayCache = false` in `UE4SS-settings.ini` (General section). This is critical for Astroneer.

## Credits
**Original Mod**: [BetterCanistersMod on Nexus Mods](https://www.nexusmods.com/astroneer/mods/51)
**Updates**: Community fixes for UE4SS v3.0.1 compatibility (Polling & Atenfyr support).
