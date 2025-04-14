local dcs_si_lfs=require('lfs')

package.path = package.path .. ";" .. dcs_si_lfs.writedir() .. "Scripts\\SayIntentions\\?.lua"

-- Imports
local json = loadfile("Scripts//JSON.lua")()
local utils = require("utils//utils")
local logger = require("utils//logger")

-- Constants
local ADAPTER_VERSION = "DCS_SIMAPI_V1"
local SIM_API_VERSION = "v1" --Should this be v1.0
local DCS_EXE = "DCS"
local OUTPUT_DIR = os.getenv("LOCALAPPDATA") .. [[\SayIntentionsAI]]
local OUTPUT_FILE_PATH = OUTPUT_DIR .. [[\simAPI_input.json]]

-- Globals
local dcsVersion = nil
local currentAircraftModule = nil
local lastSimOnGround = nil
local lastVerticalSpeed = 0
local currentModuleName = nil

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------
local function loadAircraftModule(name)
    local path = dcs_si_lfs.writedir() .. "Scripts\\SayIntentions\\aircraft\\" .. name:lower() .. ".lua"
    local aircraftScript, err = loadfile(path)

    if aircraftScript then
        local ok, mod = pcall(aircraftScript)
        if ok and type(mod) == "table" then
            return mod
        end
    else
        logger.log("Aircraft script not found: " .. path)
    end

    return nil
end

local function initializeVersionInfo()
    local version = LoGetVersionInfo()
    return string.format("DCS Version: %d.%d.%d.%d  Module: %s",
        version.ProductVersion[1],
        version.ProductVersion[2],
        version.ProductVersion[3],
        version.ProductVersion[4],
        currentModuleName
    )
end

local function calculateMagneticVariation(ownshipData)
    local trueHeading = utils.radToDeg(ownshipData.Heading)
    local magneticHeading = math.floor(LoGetMagneticYaw() * 180 / math.pi) % 360

    if magneticHeading < 0 then
        magneticHeading = magneticHeading + 360
    end

    local magvar = (magneticHeading - trueHeading + 360) % 360
    if magvar > 180 then
        magvar = magvar - 360
    end

    return magneticHeading, trueHeading, magvar
end

local function getCommonExportFields()
    local simApiJson = {}
    simApiJson["sim"] = {}

    local data = {}
    local ownshipData = LoGetSelfData()
    if not ownshipData then return data end

    local magneticHeading, trueHeading, magvar = calculateMagneticVariation(ownshipData)
    local pitch, bank = LoGetADIPitchBankYaw()
    local lat = ownshipData.LatLongAlt.Lat
    local lng = ownshipData.LatLongAlt.Long
    local windDirection, windSpeed = utils.vectorToWind(LoGetVectorWindVelocity())

    data["AIRSPEED INDICATED"] = math.floor(utils.mpsToKnots(LoGetIndicatedAirSpeed() or 0))
    data["AIRSPEED TRUE"] = math.floor(utils.mpsToKnots(LoGetTrueAirSpeed() or 0))
    data["MAGNETIC COMPASS"] = math.floor(magneticHeading or 0)
    data["MAGVAR"] = math.floor(magvar or 0)
    data["PLANE ALTITUDE"] = math.floor(utils.metersToFeet(LoGetAltitudeAboveSeaLevel() or 0))
    data["PLANE BANK DEGREES"] = math.floor(utils.radToDeg(bank or 0))
    data["PLANE PITCH DEGREES"] = math.floor(utils.radToDeg(pitch or 0))
    data["PLANE HEADING DEGREES TRUE"] = math.floor(trueHeading or 0)
    data["PLANE LATITUDE"] = lat or 0
    data["PLANE LONGITUDE"] = lng or 0
    data["SEA LEVEL PRESSURE"] = LoGetBasicAtmospherePressure() or 2992
    data["VERTICAL SPEED"] = math.floor(utils.metersPerSecondToFeetPerMinute(LoGetVerticalVelocity() or 0))
    data["AMBIENT WIND DIRECTION"] = math.floor(windDirection or 0)
    data["AMBIENT WIND VELOCITY"] = math.floor(windSpeed or 0)
    data["LOCAL TIME"] = LoGetMissionStartTime() or 0
    data["ZULU TIME"] = LoGetMissionStartTime() or 0

    -- Metadata
    simApiJson["sim"]["name"] = "DCS"
    simApiJson["sim"]["version"] = dcsVersion
    simApiJson["sim"]["adapter_version"] = ADAPTER_VERSION
    simApiJson["sim"]["simapi_version"] = SIM_API_VERSION
    simApiJson["sim"]["exe"] = DCS_EXE
    simApiJson["sim"]["variables"] = data
 
    return simApiJson
end

local function includeAircraftSpecificFields(data)
    if currentAircraftModule and currentAircraftModule.generateExportFields then
        local extra = currentAircraftModule.generateExportFields()
        for k, v in pairs(extra) do
            data["sim"]["variables"][k] = v
        end
    end
end

local function includeLandingTracking(data)
    local isOnGround = data["SIM ON GROUND"]
    local lat = data["PLANE LATITUDE"]
    local lng = data["PLANE LONGITUDE"]

    if lastSimOnGround == nil then
        lastSimOnGround = isOnGround
    elseif lastSimOnGround == 0 and isOnGround == 1 then
        data["PLANE TOUCHDOWN LATITUDE"] = lat
        data["PLANE TOUCHDOWN LONGITUDE"] = lng
        data["PLANE TOUCHDOWN NORMAL VELOCITY"] = lastVerticalSpeed
        logger.log("Aircraft has landed "..lat..", "..lng.." heading="..data["MAGNETIC COMPASS"].." indicated speed="..data["AIRSPEED INDICATED"])
    elseif lastSimOnGround == 1 and isOnGround == 0 then
        logger.log("Aircraft has taken off "..lat..", "..lng.." heading="..data["MAGNETIC COMPASS"].." indicated speed="..data["AIRSPEED INDICATED"])
    end

    lastSimOnGround = isOnGround
    lastVerticalSpeed = data["VERTICAL SPEED"]
end

local function writeExportFile(data)
    local jsonData = json:encode(data, { indent = true })
    local file = io.open(OUTPUT_FILE_PATH, "w")
    if file then
        file:write(jsonData)
        file:close()
    end
end

local function initializeModule()
    local selfData = LoGetSelfData()
    if selfData and selfData.Name then
        logger.log("Detected aircraft: " .. selfData.Name:lower())
        currentAircraftModule = loadAircraftModule(selfData.Name)
        dcsVersion = initializeVersionInfo()
    end
end

local function detectSlotChange()
    local selfData = LoGetSelfData()
    if selfData and selfData.Name then
        local latestModuleName = selfData.Name
        if latestModuleName and latestModuleName ~= currentModuleName then
            logger.log("Loading new module")
            currentModuleName = latestModuleName
            initializeModule()
        end
    end
end

local function detectDeath()
    local isDead = LoGetTrueAirSpeed() == nil
    if isDead then
        lastSimOnGround = nil
        lastVerticalSpeed = 0
        currentAircraftModule = nil
    end
end

--------------------------------------------------------------------------------
-- DCS Export Hooks
--------------------------------------------------------------------------------

function LuaExportStart()
    logger.log("Export Script Loaded.")
end

function LuaExportActivityNextEvent(timestamp)
    detectSlotChange()
    detectDeath()

    if currentAircraftModule then
        local sayIntetionsExportTable = getCommonExportFields()
        includeAircraftSpecificFields(sayIntetionsExportTable)
        includeLandingTracking(sayIntetionsExportTable)
        writeExportFile(sayIntetionsExportTable)

        -- Handle setting values in cockpit
        -- TODO
    else
        logger.log("Can not find current aircraft module")
    end

    return timestamp + 1.0
end

function LuaExportStop()
    logger.log("Export Script Stopping.")

end
