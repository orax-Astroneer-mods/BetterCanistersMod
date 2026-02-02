---@meta

---@class SimpleCanister_Options
---@field Capacity float?

---@class Canister_Options
---@field Capacity float?
---@field ItemTransferRate float?

---@class BetterCanistersMod_Options
---@field ResourceCanister_Reusable_C SimpleCanister_Options -- Small Canister
---@field ResourceCanister_Reusable_T2_C Canister_Options -- Medium Fluid & Soil Canister
---@field MediumResourceCanister_BP_C Canister_Options -- Medium Resource Canister
---@field MediumGasCanister_BP_C Canister_Options -- Medium Gas Canister
---@field ResourceCanister_Reusable_T3_C Canister_Options -- Large Fluid & Soil Canister
---@field LargeResourceCanister_BP_C Canister_Options -- Large Resource Canister
---@field LargeGasCanister_BP_C Canister_Options -- Large Gas Canister
---@field ExtraLargeResourceCanister_BP_C Canister_Options -- Extra Large Resource Canister
---@field Oxygen_Tank_Small_C SimpleCanister_Options -- Oxygen Tank

---@class ModConstantsClass
---@field name string
---@field className string
---@field shortClassName string

---@class ModConstants
---@field SmallCanister ModConstantsClass
---@field MediumFluidAndSoilCanister ModConstantsClass
---@field MediumResourceCanister ModConstantsClass
---@field MediumGasCanister ModConstantsClass
---@field LargeFluidAndSoilCanister ModConstantsClass
---@field LargeResourceCanister ModConstantsClass
---@field LargeGasCanister ModConstantsClass
---@field ExtraLargeResourceCanister ModConstantsClass
---@field OxygenTankSmall ModConstantsClass
