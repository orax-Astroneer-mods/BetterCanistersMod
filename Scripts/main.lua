--[[
FIXED VERSION - Adds support for updating EXISTING canisters on game load
Original only monitored NEW canisters, this version also searches for existing ones

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
end  -- Close onNewCanister function

--------------------------------------------------------------------------------
-- NEW: Update existing canisters when game loads
--------------------------------------------------------------------------------

-- List of all canister class names from options (MUST be defined before polling functions)
local canisterClassNames = {
    "ResourceCanister_Reusable_C",           -- Small Canister
    "ResourceCanister_Reusable_T2_C",        -- Medium Fluid & Soil Canister
    "MediumResourceCanister_BP_C",           -- Medium Resource Canister
    "MediumGasCanister_BP_C",                -- Medium Gas Canister
    "ResourceCanister_Reusable_T3_C",        -- Large Fluid & Soil Canister
    "LargeResourceCanister_BP_C",            -- Large Resource Canister
    "LargeGasCanister_BP_C",                 -- Medium Gas Canister
    "ExtraLargeResourceCanister_BP_C",       -- Extra Large Resource Canister
    "Oxygen_Tank_Small_C"                    -- Oxygen Tank
}

--------------------------------------------------------------------------------
-- Hybrid detection: Try NotifyOnNewObject, fallback to polling if broken
--------------------------------------------------------------------------------

local knownCanisters = {} -- Stores canister address -> true
local pollingActive = false
local eventBasedDetectionWorks = false -- Set to true if NotifyOnNewObject fires
local pollingInterval = 3000 -- Check every 3 seconds

local function trackCanister(canister)
    if canister and canister:IsValid() then
        local address = tostring(canister:GetAddress())
        knownCanisters[address] = true
    end
end

local function isKnownCanister(canister)
    if not canister or not canister:IsValid() then return false end
    local address = tostring(canister:GetAddress())
    return knownCanisters[address] == true
end

-- Batching system to avoid log spam
local newCanisterBatch = {}
local batchPending = false

local function reportNewCanisters()
    if #newCanisterBatch > 0 then
        log.info(format("✅ Detected and modified %d new canister(s)", #newCanisterBatch))
        newCanisterBatch = {}
    end
    batchPending = false
end

-- Called when a new canister is detected (either by event or polling)
local function onCanisterDetected(canister, source)
    if not isKnownCanister(canister) then
        trackCanister(canister)
        onNewCanister(canister)
        
        -- Add to batch
        table.insert(newCanisterBatch, canister)
        
        -- Schedule batch report if not already pending
        if not batchPending then
            batchPending = true
            ExecuteWithDelay(500, reportNewCanisters)  -- Report after 500ms
        end
    end
end

local function startPolling()
    if pollingActive then return end
    
    pollingActive = true
    pollForNewCanisters()
end

-- NotifyOnNewObject - ONLY works during save load, not for crafted items!
-- We keep this to optimize initial detection, but polling handles runtime crafting
---@param canister AResourceCanister_Reusable_C|AMediumResourceCanister_BP_C
---@diagnostic disable-next-line: redundant-parameter
NotifyOnNewObject("/Game/Items/StorageCanister_Reusable_Base.StorageCanister_Reusable_Base_C", function(canister)
    onCanisterDetected(canister, "NotifyOnNewObject")
end)

-- Polling fallback - active because NotifyOnNewObject is unreliable 
function pollForNewCanisters()
    if not pollingActive or eventBasedDetectionWorks then return end
    
    local newCanistersFound = 0
    
    for _, className in ipairs(canisterClassNames) do
        local found = FindAllOf(className)
        if found then
            for _, canister in ipairs(found) do
                if canister:IsValid() and not isKnownCanister(canister) then
                    trackCanister(canister)
                    onNewCanister(canister)
                    newCanistersFound = newCanistersFound + 1
                end
            end
        end
    end
    
    if newCanistersFound > 0 then
        log.debug(format("Detected %d new canister(s) via polling", newCanistersFound))
    end
    
    -- Schedule next poll
    ExecuteWithDelay(pollingInterval, pollForNewCanisters)
end

-- File to track which saves have been processed with options hash
local processedSavesFile = format([[%s\processed_saves.txt]], CurrentModDirectory)
local optionsFile = format([[%s\options.lua]], CurrentModDirectory)

-- Get the modification time of options.lua file
---@return number|nil
local function getOptionsModTime()
    local cmd = format([[powershell -Command "(Get-Item '%s').LastWriteTime.Ticks"]], optionsFile)
    local handle = io.popen(cmd)
    if handle then
        local result = handle:read("*a")
        handle:close()
        local modTime = tonumber(result:match("%d+"))
        return modTime
    end
    return nil
end

-- Load list of already-processed saves with their options mod time
---@return table<string, number>
local function loadProcessedSaves()
    local processed = {}
    local file = io.open(processedSavesFile, "r")
    if file then
        for line in file:lines() do
            local saveName, modTime = line:match("^%s*(.-)%s*|%s*(.-)%s*$")
            if saveName and saveName ~= "" and modTime then
                processed[saveName] = tonumber(modTime) or 0
            end
        end
        file:close()
    end
    return processed
end

-- Add a save name with current options mod time to the processed list
---@param saveName string
---@param optionsModTime number
local function markSaveAsProcessed(saveName, optionsModTime)
    local file = io.open(processedSavesFile, "a")
    if file then
        file:write(format("%s|%s\n", saveName, optionsModTime))
        file:close()
        log.info("Marked save as processed: " .. saveName)
    else
        log.error("Failed to write to processed saves file: " .. processedSavesFile)
    end
end

-- Get the current save/world name
---@return string|nil
local function getCurrentSaveName()
    -- Try to get the world name from the game using UE4SS API
    local world = FindFirstOf("World")
    if world and world:IsValid() then
        local worldName = world:GetFullName()
        -- Extract a unique identifier from the world name
        -- Format is typically: "World /Game/Maps/[MapName].[MapName]"
        local saveName = worldName:match("/([^/]+)%.[^%.]+$") or worldName
        return saveName
    end
    return nil
end
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    -- Wait a bit for world to be available
    ExecuteWithDelay(1000, function()
        local saveName = getCurrentSaveName()
        
        if not saveName then
            log.warn("Could not determine save name, skipping canister update check")
            return
        end
        
        log.debug(format("Loading save '%s'", saveName))
        
        -- Wait for world to fully load before searching
        ExecuteWithDelay(3000, function()
            local canisters = {}
            
            -- Collect all canisters
            for _, className in ipairs(canisterClassNames) do
                local found = FindAllOf(className)
                if found then
                    for _, canister in ipairs(found) do
                        if canister:IsValid() then
                            table.insert(canisters, canister)
                        end
                    end
                end
            end
            
            -- Track all existing canisters so polling can detect new ones
            for _, canister in ipairs(canisters) do
                trackCanister(canister)
            end
            
            -- ALWAYS: Apply transfer rates (they reset each load)
            local transferUpdated = 0
            for _, canister in ipairs(canisters) do
                local canisterClass = canister:GetClass():GetFName():ToString()
                if options[canisterClass] and options[canisterClass].ItemTransferRate then
                    setTransferRate(canister, options[canisterClass].ItemTransferRate)
                    transferUpdated = transferUpdated + 1
                end
            end
            
            log.info(format("✅ BetterCanisters: Modified %d existing canisters", transferUpdated))
            
            -- FIRST LOAD ONLY: Apply capacity (permanent, only needed once)
            local processedSaves = loadProcessedSaves()
            local currentOptionsModTime = getOptionsModTime() or 0
            
            local needsCapacityUpdate = false
            if not processedSaves[saveName] then
                needsCapacityUpdate = true
            elseif processedSaves[saveName] < currentOptionsModTime then
                needsCapacityUpdate = true
                log.info("Options changed - reapplying capacity")
            end
            
            if needsCapacityUpdate then
                local capacityUpdated = 0
                for _, canister in ipairs(canisters) do
                    local canisterClass = canister:GetClass():GetFName():ToString()
                    if options[canisterClass] and options[canisterClass].Capacity then
                        setCapacity(canister, options[canisterClass].Capacity)
                        capacityUpdated = capacityUpdated + 1
                    end
                end
                -- Mark save as processed
                markSaveAsProcessed(saveName, currentOptionsModTime)
            end
            
            -- Start polling for new canisters (after existing ones are tracked)
            startPolling()
        end)
    end)
end)

log.info("BetterCanistersMod loaded - will update existing and new canisters")

--------------------------------------------------------------------------------

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
