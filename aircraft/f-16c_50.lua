local utils = require("utils//utils")
local logger = require("utils//logger")

local F16 = {}
local ENABLED = 1
local DISABLED = 0

local EMPTY_WEIGHT = 19000
local MAX_INTER_FUEL_LBS = 7200
local PILOT_WEIGHT = 200
local WHEEL_RADIUS_INCH = 11

function F16.setMode3Transponder(code)
end

function F16.setCom1(freq)
    local VHFRadio = GetDevice(38)
    if VHFRadio then
        VHFRadio:set_frequency(freq)
        logger.log("Setting VHF to "..freq)
    end
end

-- 
function F16.setStandbyCom(freq)
end

local CurrentModelTime = 0
local IdentExpirationTime = 0
local Ident = DISABLED

function F16.generateExportFields()

    local Com1Freq = 0
    local IndicatedAltitude = 0
    local SimOnGround = DISABLED
    local TotalWeight = EMPTY_WEIGHT + PILOT_WEIGHT
    local WheelRPM = 0
    local Mode3Code = 0

    local VHFRadio = GetDevice(38)
    local HUD = utils.getDCSListIndication(1)
    local MainPanel = GetDevice(0)

    if MainPanel then
        local IPPushed = MainPanel:get_argument_value(125) == 1
        if IPPushed and Ident == DISABLED then
            Ident = ENABLED
            IdentExpirationTime = CurrentModelTime + 20
        end

        if Ident == ENABLED and CurrentModelTime >= IdentExpirationTime then
            Ident = DISABLED
        end
    end

    if VHFRadio then
        Com1Freq = utils.frequencyToRadioChannel(VHFRadio:get_frequency())
    end

    if HUD then
        if HUD.HUD_Altitude_num then
            local AltitudeHundreds = utils.stripStringOfNonNumbers(HUD.HUD_Altitude_num)
            IndicatedAltitude = tonumber(AltitudeHundreds) or 0
        end

        if HUD.HUD_Altitude_num_k then
            local AltitudeThousands = utils.stripStringOfNonNumbers(HUD.HUD_Altitude_num_k)
            local AltitudeThousandsNum = tonumber(AltitudeThousands) or 0
            IndicatedAltitude = IndicatedAltitude + AltitudeThousandsNum * 1000
        end
    end

    local latestAGL = LoGetAltitudeAboveGroundLevel()
    local latestEngineInfo = LoGetEngineInfo()
    local latestTAS = LoGetTrueAirSpeed() or 0

    if latestAGL and latestAGL <= 2 then
       SimOnGround = ENABLED
    end

    if latestEngineInfo and latestEngineInfo.fuel_internal then
        TotalWeight = TotalWeight + math.floor(latestEngineInfo.fuel_internal * MAX_INTER_FUEL_LBS)
    end

    if SimOnGround == ENABLED then
        WheelRPM = math.floor(utils.calculateWheelRPMFromKnotsAndRadius(latestTAS, WHEEL_RADIUS_INCH))
    else
        WheelRPM = 0
    end

    local digit1 = math.floor(GetDevice(0):get_argument_value(546) * 10 + 0.5)
    local digit2 = math.floor(GetDevice(0):get_argument_value(548) * 10 + 0.5)
    local digit3 = math.floor(GetDevice(0):get_argument_value(550) * 10 + 0.5)
    local digit4 = math.floor(GetDevice(0):get_argument_value(552) * 10 + 0.5)
    Mode3Code = digit1 * 1000 + digit2 * 100 + digit3 * 10 + digit4

    return {
        ["COM ACTIVE FREQUENCY:1"] = Com1Freq,
        ["COM RECEIVE:1"] = ENABLED,
        ["COM TRANSMIT:1"] = ENABLED,
        ["CIRCUIT COM ON:1"] = ENABLED,

        -- No Com2 in Viper :(
        ["COM ACTIVE FREQUENCY:2"] = DISABLED,
        ["COM RECEIVE:2"] = DISABLED,
        ["COM TRANSMIT:2"] = DISABLED,
        ["CIRCUIT COM ON:2"] = DISABLED,

        ["ENGINE TYPE"] = utils.SayIntetionsEngineTypes.Jet,
        ["INDICATED ALTITUDE"] = IndicatedAltitude,
        ["SIM ON GROUND"] = SimOnGround,
        ["TOTAL WEIGHT"] = TotalWeight,
        ["WHEEL_RPM:0"] = WheelRPM,
        ["WHEEL RPM:1"] = WheelRPM,
        ["ELECTRICAL MASTER BATTERY:0"] = ENABLED,
        ["TRANSPONDER STATE:1"] = 3,
        ["TRANSPONDER CODE:1"] = Mode3Code,
        ["TRANSPONDER IDENT"] = Ident,
        ["TYPICAL DESCENT RATE"] = 2500,
    }
end

return F16
