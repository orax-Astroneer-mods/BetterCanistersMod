--[[
0x3E8 ItemComponent > Capacity
0x6A8 StorageCanister > ItemTransferRate

Small Canister
Medium Fluid & Soil Canister
Medium Resource Canister
Medium Gas Canister
Large Fluid & Soil Canister
Large Resource Canister
Large Gas Canister
Extra Large Resource Canister
Oxygen Tank
]]

local logging = require("lib.lua-mods-libs.logging")

local format = string.format
local CurrentModDirectory = debug.getinfo(1, "S").source:gsub("\\", "/"):match("@?(.+)/[Ss]cripts/")

---@param filename string
---@return boolean
local function isFileExists(filename)
    local file = io.open(filename, "r")
    if file ~= nil then
        io.close(file)
        return true
    else
        return false
    end
end

---@return BetterCanistersMod_Options
local function loadOptions()
    local file = format([[%s\options.lua]], CurrentModDirectory)

    if not isFileExists(file) then
        local cmd = format([[copy "%s\options.example.lua" "%s\options.lua"]],
            CurrentModDirectory,
            CurrentModDirectory)

        print("Copy example options to options.lua. Execute command: " .. cmd .. "\n")

        os.execute(cmd)
    end

    return dofile(file)
end

--------------------------------------------------------------------------------

-- Default logging levels. They can be overwritten in the options file.
LOG_LEVEL = "INFO" ---@type _LogLevel
MIN_LEVEL_OF_FATAL_ERROR = "ERROR" ---@type _LogLevel

local options = loadOptions()
local log = logging.new(LOG_LEVEL, MIN_LEVEL_OF_FATAL_ERROR)

-- "ItemTransferRate" does not exist with the "Small Canister" and "Oxygen Tank".
options.ResourceCanister_Reusable_C.ItemTransferRate = nil ---@diagnostic disable-line: inject-field
options.Oxygen_Tank_Small_C.ItemTransferRate = nil ---@diagnostic disable-line: inject-field

--------------------------------------------------------------------------------

local function setCapacity(canister, newCapacity)
    if newCapacity == nil or not canister or not canister:IsValid() then
        return
    end

    local itemComponent = canister.ItemComponent

    if itemComponent and itemComponent:IsValid() and type(itemComponent.Capacity) == "number" then
        log.debug("Set `Capacity` value: %s => %s", itemComponent.Capacity, newCapacity)
        itemComponent.Capacity = newCapacity
    else
        log.error("Unable to get `itemComponent.Capacity` property.")
    end
end

local function setTransferRate(canister, newTransferRate)
    if newTransferRate == nil or not canister or not canister:IsValid() then
        return
    end

    local storageCanister = canister.StorageCanister
    if storageCanister and storageCanister:IsValid() and type(storageCanister.ItemTransferRate) == "number" then
        if newTransferRate ~= nil then
            log.debug("Set `ItemTransferRate` value: %s => %s", storageCanister.ItemTransferRate, newTransferRate)
            storageCanister.ItemTransferRate = newTransferRate
        end
    else
        log.error("Unable to get `StorageCanister.ItemTransferRate` property.")
    end
end

---@param canister AResourceCanister_Reusable_C|AMediumResourceCanister_BP_C
local function onNewCanister(canister)
    local canisterClass = canister:GetClass():GetFName():ToString()
    log.debug("New canister: " .. canisterClass .. " " .. canister:GetFullName())

    if not options[canisterClass] then
        log.debug("No options for: " .. canisterClass)
        return
    end

    local newCapacity = options[canisterClass].Capacity
    setCapacity(canister, newCapacity)

    local newTransferRate = options[canisterClass].ItemTransferRate
    -- a delay sometimes seems necessary
    ExecuteWithDelay(1000, function()
        if not canister:IsValid() then
            log.debug("WARN: The instance is no longer valid. " .. canister:GetFullName())
            return
        end

        log.trace(canister:GetFullName())
        setCapacity(canister, newCapacity)
        setTransferRate(canister, newTransferRate)
    end)
end

---@param canister AResourceCanister_Reusable_C|AMediumResourceCanister_BP_C
---@diagnostic disable-next-line: redundant-parameter
NotifyOnNewObject("/Game/Items/StorageCanister_Reusable_Base.StorageCanister_Reusable_Base_C", function(canister)
    onNewCanister(canister)
end)

local function printDefaultGameValues(classInfo)
    local shortClassName = classInfo.shortClassName

    ---@type AMediumResourceCanister_BP_C[]?
    local instances = FindAllOf(shortClassName)
    if not instances then
        log.warn("No instance found for: " .. shortClassName)
        return
    end

    for _, instance in pairs(instances) do
        local instanceClassName = instance:GetClass():GetFullName():gsub("^%w+ ", "")

        if instance:IsA(classInfo.className) and instanceClassName == classInfo.className then
            local itemTransferRate = type(instance.StorageCanister.ItemTransferRate) == "number" and
                instance.StorageCanister.ItemTransferRate or
                "N/A"

            return format("%s,%s,%s\n",
                classInfo.name, instance.ItemComponent.Capacity, itemTransferRate)
        end
    end
end

-- Must be run on a clean set (without modified values).
-- local C = require("constants") ---@type ModConstants
-- local str = "\nDefault game values:\n"
-- str = str .. "Name,Capacity,Transfer rate\n"
-- str = str .. printDefaultGameValues(C.SmallCanister)
-- str = str .. printDefaultGameValues(C.MediumFluidAndSoilCanister)
-- str = str .. printDefaultGameValues(C.MediumResourceCanister)
-- str = str .. printDefaultGameValues(C.MediumGasCanister)
-- str = str .. printDefaultGameValues(C.LargeFluidAndSoilCanister)
-- str = str .. printDefaultGameValues(C.LargeResourceCanister)
-- str = str .. printDefaultGameValues(C.LargeGasCanister)
-- str = str .. printDefaultGameValues(C.ExtraLargeResourceCanister)
-- str = str .. printDefaultGameValues(C.OxygenTankSmall)
-- print(str)

-- Run tests.
-- Copy options.test.lua content into options.lua. Reload mod to run tests.
-- require("test.test").runTests()
