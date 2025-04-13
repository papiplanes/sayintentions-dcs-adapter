package.path = package.path .. ";" .. g_lfs.writedir() .. "Scripts\\SayIntentions\\?.lua"

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

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------
local function loadAircraftModule(name)
    local path = g_lfs.writedir() .. "Scripts\\SayIntentions\\aircraft\\" .. name:lower() .. ".lua"
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
    return string.format("ProductVersion: %d.%d.%d.%d",
        version.ProductVersion[1],
        version.ProductVersion[2],
        version.ProductVersion[3],
        version.ProductVersion[4]
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
    local data = {}
    local ownshipData = LoGetSelfData()
    if not ownshipData then return data end

    local magneticHeading, trueHeading, magvar = calculateMagneticVariation(ownshipData)
    local pitch, bank = LoGetADIPitchBankYaw()
    local lat = ownshipData.LatLongAlt.Lat
    local lng = ownshipData.LatLongAlt.Long
    local windDirection, windSpeed = utils.vectorToWind(LoGetVectorWindVelocity())

    data["AIRSPEED INDICATED"] = math.floor(utils.mpsToKnots(LoGetIndicatedAirSpeed()))
    data["AIRSPEED TRUE"] = math.floor(utils.mpsToKnots(LoGetTrueAirSpeed()))
    data["MAGNETIC COMPASS"] = math.floor(magneticHeading)
    data["MAGVAR"] = math.floor(magvar)
    data["PLANE ALTITUDE"] = math.floor(utils.metersToFeet(LoGetAltitudeAboveSeaLevel()))
    data["PLANE BANK DEGREES"] = math.floor(utils.radToDeg(bank))
    data["PLANE PITCH DEGREES"] = math.floor(utils.radToDeg(pitch))
    data["PLANE HEADING DEGREES TRUE"] = math.floor(trueHeading)
    data["PLANE LATITUDE"] = lat
    data["PLANE LONGITUDE"] = lng
    data["SEA LEVEL PRESSURE"] = LoGetBasicAtmospherePressure() or 2992
    data["VERTICAL SPEED"] = math.floor(utils.metersPerSecondToFeetPerMinute(LoGetVerticalVelocity()))
    data["AMBIENT WIND DIRECTION"] = math.floor(windDirection)
    data["AMBIENT WIND VELOCITY"] = math.floor(windSpeed)
    data["LOCAL TIME"] = LoGetMissionStartTime()
    data["ZULU TIME"] = LoGetMissionStartTime()

    -- Metadata
    data["name"] = "DCS"
    data["version"] = dcsVersion
    data["adapter_version"] = ADAPTER_VERSION
    data["simapi_version"] = SIM_API_VERSION
    data["exe"] = DCS_EXE

    return data
end

local function includeAircraftSpecificFields(data)
    if currentAircraftModule and currentAircraftModule.generateExportFields then
        local extra = currentAircraftModule.generateExportFields()
        for k, v in pairs(extra) do
            data[k] = v
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

--------------------------------------------------------------------------------
-- DCS Export Hooks
--------------------------------------------------------------------------------

function LuaExportStart()
    local selfData = LoGetSelfData()
    if selfData and selfData.Name then
        dcsVersion = initializeVersionInfo()
        logger.log("Detected aircraft: " .. selfData.Name:lower())
        currentAircraftModule = loadAircraftModule(selfData.Name)
    end
end

function LuaExportActivityNextEvent(timestamp)
    -- When we have a valid aircraft, build the export json for Say Intentions AI
    if currentAircraftModule then
        local sayIntetionsExportTable = getCommonExportFields()
        includeAircraftSpecificFields(sayIntetionsExportTable)
        includeLandingTracking(sayIntetionsExportTable)
        writeExportFile(sayIntetionsExportTable)

        -- Handle setting values in cockpit
        -- TODO
    end
    return timestamp + 1.0
end

function LuaExportStop()
    -- Optional cleanup logic
end
