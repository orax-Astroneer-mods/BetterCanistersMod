--[[
https://astroneer.fandom.com/wiki/Canisters
]]

local C = {
    -- Small Canister
    SmallCanister = {
        name = "Small Canister",
        className = "/Game/Items/ResourceCanister_Reusable.ResourceCanister_Reusable_C",
        shortClassName = "ResourceCanister_Reusable_C"
    },

    -- Medium Fluid & Soil Canister
    MediumFluidAndSoilCanister = {
        name = "Medium Fluid & Soil Canister",
        className = "/Game/Items/ResourceCanister_Reusable_T2.ResourceCanister_Reusable_T2_C",
        shortClassName = "ResourceCanister_Reusable_T2_C"
    },

    -- Medium Resource Canister
    MediumResourceCanister = {
        name = "Medium Resource Canister",
        className = "/Game/Items/Canisters/MediumResourceCanister_BP.MediumResourceCanister_BP_C",
        shortClassName = "MediumResourceCanister_BP_C"
    },

    -- Medium Gas Canister
    MediumGasCanister = {
        name = "Medium Gas Canister",
        className = "/Game/Items/Canisters/MediumGasCanister_BP.MediumGasCanister_BP_C",
        shortClassName = "MediumGasCanister_BP_C"
    },

    -- Large Fluid & Soil Canister
    LargeFluidAndSoilCanister = {
        name = "Large Fluid & Soil Canister",
        className = "/Game/Items/ResourceCanister_Reusable_T3.ResourceCanister_Reusable_T3_C",
        shortClassName = "ResourceCanister_Reusable_T3_C"
    },

    -- Large Resource Canister
    LargeResourceCanister = {
        name = "Large Resource Canister",
        className = "/Game/Items/Canisters/LargeResourceCanister_BP.LargeResourceCanister_BP_C",
        shortClassName = "LargeResourceCanister_BP_C"
    },

    -- Large Gas Canister
    LargeGasCanister = {
        name = "Large Gas Canister",
        className = "/Game/Items/Canisters/LargeGasCanister_BP.LargeGasCanister_BP_C",
        shortClassName = "LargeGasCanister_BP_C"
    },

    -- Extra Large Resource Canister
    ExtraLargeResourceCanister = {
        name = "Extra Large Resource Canister",
        className = "/Game/Items/Canisters/ExtraLargeResourceCanister_BP.ExtraLargeResourceCanister_BP_C",
        shortClassName = "ExtraLargeResourceCanister_BP_C"
    },

    -- Oxygen Tank
    OxygenTankSmall = {
        name = "Oxygen Tank",
        className = "/Game/Components_Small/Oxygen_Tank_Small.Oxygen_Tank_Small_C",
        shortClassName = "Oxygen_Tank_Small_C"
    }
}

return setmetatable(C, {
    __newindex = function()
        error("Attempt to modify constant.")
    end
})
