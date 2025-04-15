local utils = require("utils//utils")
local logger = require("utils//logger")

local FA18 = {}
local DISABLED = 0
local ENABLED = 1

local PILOT_WEIGHT = 200
local TYPICAL_DESCENT_RATE_FPM = 2500
local ENGINE_TYPE = utils.SayIntetionsEngineTypes.Jet
local MAX_FUEL_INTERNAL_LBS = 11000
local EMPTY_WEIGHT_LBS = 24500
local WHEEL_RADIUS_INCH = 11

local IdentExpirationTime = nil

local Ident = DISABLED
local IFF = DISABLED
local Mode3Code = 0

function FA18.setMode3Transponder(code)
    logger.log("TODO: Implement Setting Mode 3 Transponder in Hornet")
end

function FA18.setCom1(freq)
    local UHF1 = GetDevice(38)
    if UHF1 then
        UHF1:set_frequency(freq)
        logger.log("Set UHF1 freq to: "..freq)
    end
end

function FA18.generateExportFields()
    local MainPanel = GetDevice(0)
    local UHF1 = GetDevice(38)
    local UHF2 = GetDevice(39)
    local HUD = utils.getDCSListIndication(1)
    local UFC = utils.getDCSListIndication(6)

    local BatterySwitch = DISABLED
    local Com1Freq = 0
    local Com2Freq = 0
    local Com1Volume = 0
    local Com2Volume = 0
    local Com1Enabled = DISABLED
    local Com2Enabled = DISABLED
    local IndicatedAltitude = 0
    local IsOnGround = DISABLED
    local TotalWeight = 0
    local WheelRPM = 0
    local CurrentModelTime = LoGetModelTime()

    if HUD then
        local ThousandsHudValueAlt = HUD.HUD_altitude_above_1000_thousands
        local HundredsHudValueAlt = HUD.HUD_altitude_above_1000_hund_tenths
        local AltitudeBelow100 = HUD.HUD_altitude_below_1000
        if ThousandsHudValueAlt ~= nil then
            local cleanedThousands =  string.gsub(ThousandsHudValueAlt, "%D", "") or "0"
            local numberThousdands = tonumber(cleanedThousands)
            IndicatedAltitude = numberThousdands * 1000
        end

        if HundredsHudValueAlt ~= nil then
            local cleanedHundreds =  string.gsub(HundredsHudValueAlt, "%D", "") or "0"
            local numberHundreds = tonumber(cleanedHundreds)
            IndicatedAltitude = IndicatedAltitude + numberHundreds
        else
            local cleanBelow1000 =  string.gsub(AltitudeBelow100, "%D", "") or "0"
            IndicatedAltitude = tonumber(cleanBelow1000) or 0
        end
    end

    if MainPanel then
        BatterySwitch = MainPanel:get_argument_value(404) == 1 and ENABLED or DISABLED
        Com1Volume = MainPanel:get_argument_value(108) * 100
        Com2Volume = MainPanel:get_argument_value(123) * 100
        Com1Enabled = Com1Volume > 0 and ENABLED or DISABLED
        Com2Enabled = Com2Volume > 0 and ENABLED or DISABLED

        local IPPushed = MainPanel:get_argument_value(99) == 1
        if IPPushed and Ident == DISABLED then
            Ident = ENABLED
            IdentExpirationTime = CurrentModelTime + 20
        end

        if Ident == ENABLED and CurrentModelTime >= IdentExpirationTime then
            Ident = DISABLED
        end
    end

    if UHF1 then
        Com1Freq = utils.frequencyToRadioChannel(UHF1:get_frequency())
    end

    if UHF2 then
        Com2Freq = utils.frequencyToRadioChannel(UHF2:get_frequency())
    end

    if UFC and UFC.UFC_OptionDisplay2 == "2   " then
        local SIMAPI_TRANSPODER_ON = 3
        IFF = UFC.UFC_ScratchPadString1Display == 'X' and SIMAPI_TRANSPODER_ON or DISABLED
        local ExtractedMode3Code = tonumber(string.match(UFC.UFC_ScratchPadNumberDisplay, "3-[0-7][0-7][0-7][0-7]"))
        if ExtractedMode3Code then
            Mode3Code = ExtractedMode3Code
        end
    end

    local latestAGL = LoGetAltitudeAboveGroundLevel()
    local latestEngineInfo = LoGetEngineInfo()
    local latestTAS = LoGetTrueAirSpeed() or 0

    IsOnGround = DISABLED
    if latestAGL and latestAGL <= 2 then
        IsOnGround = ENABLED
    end

    TotalWeight = EMPTY_WEIGHT_LBS + PILOT_WEIGHT
    if latestEngineInfo and latestEngineInfo.fuel_internal then 
        TotalWeight = TotalWeight + math.floor(latestEngineInfo.fuel_internal * MAX_FUEL_INTERNAL_LBS)
    end

    if IsOnGround == ENABLED then
        WheelRPM = math.floor(utils.calculateWheelRPMFromKnotsAndRadius(latestTAS, WHEEL_RADIUS_INCH))
    else
        WheelRPM = 0
    end

    return {
        ["COM ACTIVE FREQUENCY:1"] = Com1Freq,
        ["COM ACTIVE FREQUENCY:2"] = Com2Freq,
        ["COM RECEIVE:1"] = Com1Enabled,
        ["COM RECEIVE:2"] = Com2Enabled,
        ["COM TRANSMIT:1"] = Com1Enabled,
        ["COM TRANSMIT:2"] = Com2Enabled,
        ["ENGINE TYPE"] = ENGINE_TYPE,
        ["INDICATED ALTITUDE"] = IndicatedAltitude,
        ["SIM ON GROUND"] = IsOnGround,
        ["TOTAL WEIGHT"] = TotalWeight,
        ["WHEEL RPM:1"] = WheelRPM,
        ["CIRCUIT COM ON:1"] = ENABLED,
        ["CIRCUIT COM ON:2"] = ENABLED,
        ["ELECTRICAL MASTER BATTERY:0"] = BatterySwitch,
        ["TRANSPONDER STATE:1"] = IFF,
        ["TRANSPONDER CODE:1"] = Mode3Code,
        ["TRANSPONDER IDENT"] = Ident,
        ["TYPICAL DESCENT RATE"] = TYPICAL_DESCENT_RATE_FPM,
    }
end

return FA18
