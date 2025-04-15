local lfs = require('lfs')
local logger = require("utils//logger")
local utils = require("utils//utils")
local ModuleManager = {}

ModuleManager.currentModule = nil
ModuleManager.currentModuleName = nil

local function detectSlotChange()
    local selfData = LoGetSelfData()
    if selfData and selfData.Name then
        local latestModuleName = selfData.Name
        if latestModuleName ~= ModuleManager.currentModuleName then
            ModuleManager.initalizeModule(selfData.Name)
        end
    end
end

local function detectDeath()
    local isDead = LoGetTrueAirSpeed() == nil
    if isDead then
        ModuleManager.reset()
    end
end

function ModuleManager.initalizeModule(name)
    local path = lfs.writedir() .. "Scripts\\SayIntentions\\aircraft\\" .. name:lower() .. ".lua"
    local aircraftScript, _ = loadfile(path)

    if aircraftScript then
        local ok, mod = pcall(aircraftScript)
        if ok and type(mod) == "table" then
            ModuleManager.currentModule = mod
            ModuleManager.currentModuleName = name
        end
    else
        logger.log("Aircraft script not found: " .. path)
    end
end

function ModuleManager.update()
    detectSlotChange()
    detectDeath()
    -- Todo handle landing detection
end

function ModuleManager.reset()
    ModuleManager.currentModule = nil
    ModuleManager.currentModuleName = nil
end

function ModuleManager.getExportFields()
    local exportFields = {}
    local ownshipData = LoGetSelfData()

    local trueHeading = utils.radToDeg(ownshipData.Heading)
    local magneticHeading = utils.radToDeg(LoGetMagneticYaw())
    local magVariation = utils.calculateMagneticVariation(trueHeading, magneticHeading)

    local pitch, bank = LoGetADIPitchBankYaw()
    local lat = ownshipData.LatLongAlt.Lat
    local lng = ownshipData.LatLongAlt.Long
    local windDirection, windSpeed = utils.vectorToWind(LoGetVectorWindVelocity())

    exportFields["AIRSPEED INDICATED"] = math.floor(utils.mpsToKnots(LoGetIndicatedAirSpeed() or 0))
    exportFields["AIRSPEED TRUE"] = math.floor(utils.mpsToKnots(LoGetTrueAirSpeed() or 0))
    exportFields["MAGNETIC COMPASS"] = math.floor(magneticHeading or 0)
    exportFields["MAGVAR"] = math.floor(magVariation or 0)
    exportFields["PLANE ALTITUDE"] = math.floor(utils.metersToFeet(LoGetAltitudeAboveSeaLevel() or 0))
    exportFields["PLANE PITCH DEGREES"] = math.floor(utils.radToDeg(pitch or 0))
    exportFields["PLANE BANK DEGREES"] = math.floor(utils.radToDeg(bank or 0))
    exportFields["PLANE HEADING DEGREES TRUE"] = math.floor(trueHeading or 0)
    exportFields["PLANE LATITUDE"] = lat or 0
    exportFields["PLANE LONGITUDE"] = lng or 0
    exportFields["SEA LEVEL PRESSURE"] = LoGetBasicAtmospherePressure() or 2992
    exportFields["VERTICAL SPEED"] = math.floor(utils.metersPerSecondToFeetPerMinute(LoGetVerticalVelocity() or 0))
    exportFields["AMBIENT WIND DIRECTION"] = math.floor(windDirection or 0)
    exportFields["AMBIENT WIND VELOCITY"] = math.floor(windSpeed or 0)
    exportFields["LOCAL TIME"] = LoGetMissionStartTime() or 0
    exportFields["ZULU TIME"] = LoGetMissionStartTime() or 0

    -- Load module specific fields (Com, Transponder, Fuel)
    local moduleFields = ModuleManager.currentModule.generateExportFields()
    for key, value in pairs(moduleFields) do
        exportFields[key] = value
    end

    return exportFields
end

function ModuleManager.processSimAPICommands(latestCommands)
    if latestCommands == nil or latestCommands == {} then return end

    local currentModule = ModuleManager.currentModule

    for command, value in pairs(latestCommands) do

        if command == 'COM_RADIO_SET_HZ' then
            if currentModule and currentModule.setCom1 then
                local freqNumber = tonumber(value)
                if freqNumber and freqNumber ~= nil then
                    currentModule.setCom1(freqNumber)
                end
            end

        elseif command == 'COM_STBY_RADIO_SET_HZ' then
            if currentModule and currentModule.setStandbyCom then
                currentModule.setStandbyCom(value)
            end

        elseif command == 'XPNDR_SET' then
            if currentModule and currentModule.setMode3Transponder then
                currentModule.setMode3Transponder(value)
            end
        end
    end
end

return ModuleManager