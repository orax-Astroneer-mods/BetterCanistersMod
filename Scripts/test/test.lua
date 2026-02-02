local C = require("constants") ---@type ModConstants

local logging = require("lib.lua-mods-libs.logging")

local format = string.format
local CurrentModDirectory = debug.getinfo(1, "S").source:gsub("\\", "/"):match("@?(.+)/[Ss]cripts/")

---@return BetterCanistersMod_Options
local function loadTestOptions()
    local file = format([[%s\Scripts\test\options.test.lua]], CurrentModDirectory)

    return dofile(file)
end

LOG_LEVEL = "INFO" ---@type _LogLevel
MIN_LEVEL_OF_FATAL_ERROR = "ERROR" ---@type _LogLevel

local options = loadTestOptions()
local log = logging.new(LOG_LEVEL, MIN_LEVEL_OF_FATAL_ERROR)

local function testCanister(classInfo, notTestTransferRate)
    log.info("# Test " .. classInfo.shortClassName .. " ", classInfo.className)

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
            if instance.ItemComponent.Capacity == options[shortClassName].Capacity then
                log.info("%s Capacity: OK. %s", shortClassName, instance:GetFullName())
            else
                log.info("%s Capacity: FAIL (%s ~= %s). %s",
                    shortClassName,
                    instance.ItemComponent.Capacity, options[shortClassName].Capacity,
                    instance:GetFullName())
            end

            if notTestTransferRate ~= true then
                if instance.StorageCanister.ItemTransferRate == options[shortClassName].ItemTransferRate then
                    log.info("%s ItemTransferRate: OK. %s", shortClassName, instance:GetFullName())
                else
                    log.info("%s ItemTransferRate: FAIL (%s ~= %s). %s",
                        shortClassName,
                        instance.StorageCanister.ItemTransferRate, options[shortClassName].ItemTransferRate,
                        instance:GetFullName())
                end
            end
        end
    end
end

local function runTests()
    testCanister(C.SmallCanister, true)
    testCanister(C.MediumFluidAndSoilCanister)
    testCanister(C.MediumResourceCanister)
    testCanister(C.MediumGasCanister)
    testCanister(C.LargeFluidAndSoilCanister)
    testCanister(C.LargeResourceCanister)
    testCanister(C.LargeGasCanister)
    testCanister(C.ExtraLargeResourceCanister)
    testCanister(C.OxygenTankSmall, true)
end

return { runTests = runTests }
