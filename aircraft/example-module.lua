local utils = require("utils//utils")
local logger = require("utils//logger")

local ExampleModule = {}

-- The file name for this file is `example-module.lua`
-- If you are adding a new module, you can load up DCS with this SayIntentions export script added
-- and visit <USER>/Saved Games/<DCS>/Logs/SayIntentions.log
-- to find the expected file name for a given module 
-- (Hint: its the lower case version of how DCS references module names)
-- Example: Huey = u1-1h, Hornet = fa-18c_hornet
-- The ModuleManager will take the DCS Module name and try to find the correct aircraft module lua file to use. 

--------------------------------------------------------------------------------
-- Functions for Module To Support "SimAPI Output Commands"
-- See all possible output variables here
-- https://portal.sayintentions.ai/simapi/v1/output_variables.txt
-- Currently, this plugin supports these 3 basic output variables to be set
-- This is module specific, some modules may not implement some due to in-ability
-- Example: Hornet- setting the Mode 3 Transponder requires a series of buttons to be pressed on UFC_1
-----------------------------------------------------------------------------------

function ExampleModule.setMode3Transponder(code)
    -- TODO
end

function ExampleModule.setCom1(freq)
    -- TODO
end

-- 
function ExampleModule.setStandbyCom(freq)
    -- TODO
end

-- Method generates module specific export fields
-- This is a DCS concept since in DCS, each module has its own way
-- of getting data out of a module. 
-- All other "base fields" are handled for you and you do not need to calculate them
-- You can find a list of ALL SayIntentionsAI SimAPI variables here:
-- https://portal.sayintentions.ai/simapi/v1/input_variables.txt

-- All aircraft module files must have a `generateExportFields()` method
function ExampleModule.generateExportFields()

    -- Below are hardcoded exported fields for a module
    -- You can view the `fa-18c_hornet.lua` file or the `uh-1h.lua` file 
    -- for examples of how to fetch these fields from DCS Modules

    return {
        ["COM ACTIVE FREQUENCY:1"] = 121.5,  -- Number: Frequency of radio 2
        ["COM ACTIVE FREQUENCY:2"] = 122.45, -- Number: Frequency of radio 2
        ["COM RECEIVE:1"] = 1,               -- Number: 1 = On, 0 = Off
        ["COM RECEIVE:2"] = 0,               -- Number: 1 = On, 0 = Off
        ["COM TRANSMIT:1"] = 1,              -- Number: 1 = On, 0 = Off
        ["COM TRANSMIT:2"] = 0,              -- Number: 1 = On, 0 = Off
        ["ENGINE TYPE"] = 3,                 -- Number: 1 = On, 0 = Off
        ["INDICATED ALTITUDE"] = 4433,       -- Number: Indicated Altitude on Gauge/HUD in Feet
        ["SIM ON GROUND"] = 0,               -- Number: 1 = On Ground, 0 = In Air
        ["TOTAL WEIGHT"] = 22000,            -- Number: Total Weight (Fuel+Payload+Airframe) in LBS
        ["WHEEL RPM:1"] = 0,                 -- Number: RPM of wheel on ground
        ["CIRCUIT COM ON:1"] = 1,            -- Number: 1 = On, 0 = Off
        ["CIRCUIT COM ON:2"] = 0,            -- Number: 1 = On, 0 = Off
        ["ELECTRICAL MASTER BATTERY:0"] = 1, -- Number: 1 = On, 0 = Off
        ["TRANSPONDER STATE:1"] = 3,         -- Number: 3 means On
        ["TRANSPONDER CODE:1"] = 7777,       -- Number: Mode 3 Transponder Code
        ["TRANSPONDER IDENT"] = 1,           -- Number: 1 = Identing, 0 = Not Identing
        ["TYPICAL DESCENT RATE"] = 2500,     -- Number: Normal descent rate FPM
    }
end

return ExampleModule
