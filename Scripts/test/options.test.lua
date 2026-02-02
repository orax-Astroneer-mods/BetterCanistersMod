--[[
# This file is a Lua file.
Lua (programming language): https://en.wikipedia.org/wiki/Lua_(programming_language)

## Comments
Everything after -- (two hyphens/dashes) is ignored (it's a commentary),
so if you want to turn off any option, just put -- in the beginning of the line.
https://www.codecademy.com/resources/docs/lua/comments

https://astroneer.fandom.com/wiki/Canisters
https://astroneer.fandom.com/wiki/Oxygen_Tank
--]]

-- Valid values: ALL, TRACE, DEBUG, INFO, WARN, ERROR, FATAL, OFF
LOG_LEVEL = "INFO" ---@type _LogLevel
MIN_LEVEL_OF_FATAL_ERROR = "ERROR" ---@type _LogLevel

---@type BetterCanistersMod_Options
local options = {
    ResourceCanister_Reusable_C = {
        Capacity = 1,
    },
    ResourceCanister_Reusable_T2_C = {
        Capacity = 2,
        ItemTransferRate = 12
    },
    MediumResourceCanister_BP_C = {
        Capacity = 3,
        ItemTransferRate = 13
    },
    MediumGasCanister_BP_C = {
        Capacity = 4,
        ItemTransferRate = 14
    },
    ResourceCanister_Reusable_T3_C = {
        Capacity = 5,
        ItemTransferRate = 15
    },
    LargeResourceCanister_BP_C = {
        Capacity = 6,
        ItemTransferRate = 16
    },
    LargeGasCanister_BP_C = {
        Capacity = 7,
        ItemTransferRate = 17
    },
    ExtraLargeResourceCanister_BP_C = {
        Capacity = 8,
        ItemTransferRate = 18
    },
    Oxygen_Tank_Small_C = {
        Capacity = 9
    }
}

return options
