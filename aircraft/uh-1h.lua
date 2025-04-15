local utils = require("utils//utils")
local logger = require("utils//logger")

local UH1H = {}
local DISABLED = 0
local ENABLED = 1

local PILOT_WEIGHT = 200
local COPILOT_WEIGHT = 200
local TYPICAL_DESCENT_RATE_FPM = 500
local ENGINE_TYPE = utils.SayIntetionsEngineTypes.TurbineHelicopter
local MAX_FUEL_INTERNAL_LBS = 1400


function UH1H.setMode3Transponder(code)
    -- TODO
end

function UH1H.setCom1(freq)
    local VHFRadio = GetDevice(20)
    if VHFRadio then
        VHFRadio:set_frequency(freq)
        logger.log("Set VHF freq to: "..freq)
    end
end

function UH1H.generateExportFields()
    local MainPanel = GetDevice(0)
    local VHFRadio = GetDevice(20)
    local Com1ActiveFreq = 0
    local IndicatedAltitude = 0
    local MasterBattery = 0
    local IFFState = 0
    local Mode3Code = 0
    local IdentSwitch = 0

    if MainPanel then

        -- DCS Huey Battery Switch: 0 means switch is enabled, tell SI
        MasterBattery = MainPanel:get_argument_value(219) == 0 and ENABLED or DISABLED

        IFFState = math.floor((MainPanel:get_argument_value(59) + 0.05) * 10)

        local ThousandsNeedle = MainPanel:get_argument_value(179)
        if ThousandsNeedle < 0.995 then
            ThousandsNeedle = math.floor(ThousandsNeedle * 10)
        else
            ThousandsNeedle = 0
        end

        local TensNeedle = MainPanel:get_argument_value(180)
        if TensNeedle < 0.985 then
            TensNeedle = math.floor(TensNeedle * 1000)
        else
            TensNeedle = 0
        end
        IndicatedAltitude = ThousandsNeedle * 1000+ TensNeedle
 
        local Wheel1 = math.floor(MainPanel:get_argument_value(70) * 10)
        local Wheel2 = math.floor(MainPanel:get_argument_value(71) * 10)
        local Wheel3 = math.floor(MainPanel:get_argument_value(72) * 10)
        local Wheel4 = math.floor(MainPanel:get_argument_value(73) * 10)
        Mode3Code = Wheel1 * 1000 + Wheel2 * 100 + Wheel3 * 10 + Wheel4

        IdentSwitch = MainPanel:get_argument_value(66) == 1 and ENABLED or DISABLED

        if VHFRadio then
            Com1ActiveFreq = utils.frequencyToRadioChannel(VHFRadio:get_frequency())
        end
    end

    -- 1 if Huey is less than 2 meters above ground, else 0
    local OnGround = (LoGetAltitudeAboveGroundLevel() <= 2) and 1 or 0


    local FuelLbs = LoGetEngineInfo().fuel_internal * MAX_FUEL_INTERNAL_LBS
    local Payload = FuelLbs + PILOT_WEIGHT + COPILOT_WEIGHT

    return {
        ["COM ACTIVE FREQUENCY:1"] = Com1ActiveFreq,
        ["COM ACTIVE FREQUENCY:2"] = DISABLED,
        ["COM RECEIVE:1"] = ENABLED,
        ["COM RECEIVE:2"] = DISABLED,
        ["COM TRANSMIT:1"] = ENABLED,
        ["COM TRANSMIT:2"] = DISABLED,
        ["ENGINE TYPE"] = ENGINE_TYPE,
        ["INDICATED ALTITUDE"] = IndicatedAltitude,
        ["SIM ON GROUND"] = OnGround,
        ["TOTAL WEIGHT"] = Payload,
        ["WHEEL RPM:1"] = DISABLED,
        ["CIRCUIT COM ON:1"] = ENABLED,
        ["CIRCUIT COM ON:2"] = DISABLED,
        ["ELECTRICAL MASTER BATTERY:0"] = MasterBattery,
        ["TRANSPONDER STATE:1"] = IFFState,
        ["TRANSPONDER CODE:1"] = Mode3Code,
        ["TRANSPONDER IDENT"] = IdentSwitch,
        ["TYPICAL DESCENT RATE"] = TYPICAL_DESCENT_RATE_FPM,
    }
end

return UH1H
