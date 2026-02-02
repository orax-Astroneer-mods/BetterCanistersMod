--[[
# This file is a Lua file.
Lua (programming language): https://en.wikipedia.org/wiki/Lua_(programming_language)

# Comments
Everything after -- (two hyphens/dashes) is ignored (it's a commentary),
so if you want to turn off any option, just put -- in the beginning of the line.
https://www.codecademy.com/resources/docs/lua/comments

# Wiki
https://astroneer.fandom.com/wiki/Canisters
https://astroneer.fandom.com/wiki/Oxygen_Tank
--]]

--[[
# Default game values

+-------------------------------+----------+---------------+
| Name                          | Capacity | Transfer rate |
+-------------------------------+----------+---------------+
| Small Canister                | 1.0      | N/A           |
| Medium Fluid & Soil Canister  | 24.0     | 1.0           |
| Medium Resource Canister      | 32.0     | 1.0           |
| Medium Gas Canister           | 160.0    | 5.0           |
| Large Fluid & Soil Canister   | 300.0    | 1.0           |
| Large Resource Canister       | 400.0    | 1.0           |
| Large Gas Canister            | 2000.0   | 5.0           |
| Extra Large Resource Canister | 2000.0   | 3.0           |
| Oxygen Tank                   | 2.0      | N/A           |
+-------------------------------+----------+---------------+
]]

---@type BetterCanistersMod_Options
local options = {
    -- Small Canister
    ResourceCanister_Reusable_C = {
        Capacity = 1,
    },

    -- Medium Fluid & Soil Canister
    ResourceCanister_Reusable_T2_C = {
        Capacity = 24,
        ItemTransferRate = 50
    },

    -- Medium Resource Canister
    MediumResourceCanister_BP_C = {
        Capacity = 32,
        ItemTransferRate = 50
    },

    -- Medium Gas Canister
    MediumGasCanister_BP_C = {
        Capacity = 160,
        ItemTransferRate = 50
    },

    -- Large Fluid & Soil Canister
    ResourceCanister_Reusable_T3_C = {
        Capacity = 300,
        ItemTransferRate = 50
    },

    -- Large Resource Canister
    LargeResourceCanister_BP_C = {
        Capacity = 400,
        ItemTransferRate = 50
    },

    -- Large Gas Canister
    LargeGasCanister_BP_C = {
        Capacity = 2000,
        ItemTransferRate = 50
    },

    -- Extra Large Resource Canister
    ExtraLargeResourceCanister_BP_C = {
        Capacity = 2000,
        ItemTransferRate = 50
    },

    -- Oxygen Tank
    Oxygen_Tank_Small_C = {
        Capacity = 2
    }
}

-- Valid values: ALL, TRACE, DEBUG, INFO, WARN, ERROR, FATAL, OFF
LOG_LEVEL = "INFO" ---@type _LogLevel
MIN_LEVEL_OF_FATAL_ERROR = "ERROR" ---@type _LogLevel

return options
