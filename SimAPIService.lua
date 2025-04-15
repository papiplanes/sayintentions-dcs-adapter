local json = loadfile("Scripts//JSON.lua")()
local logger = require("utils//logger")
local utils = require("utils//utils")
local SimAPIService = {}
local lfs=require('lfs')

-- Constants for file IO
local OUTPUT_DIR = os.getenv("LOCALAPPDATA") .. [[\SayIntentionsAI]]
local SIMAPI_INPUT_FILE = OUTPUT_DIR .. [[\simAPI_input.json]]
local SIMAPI_OUTPUT_FILE = OUTPUT_DIR .. [[\simapi_output.jsonl]]

-- Local Variables
local lastSimAPIOutputTimestamp = nil

-- Version Information For SimAPI
SimAPIService.version = "unknown"
SimAPIService.adapter_version = "DCS_SIMAPI_V1.0"
SimAPIService.simapi_version = "v1"
SimAPIService.simulator_exe_title = "DCS"
SimAPIService.name = "DCS"

function SimAPIService.initalize()
    SimAPIService.version = utils.getDCSVersionInfromation()
end

function SimAPIService.writeExportFile(exportFields, moduleName)
    local simApiJson = {}
    simApiJson["sim"] = {}

    simApiJson["sim"]["version"] = SimAPIService.version.. " "..moduleName
    simApiJson["sim"]["name"] = SimAPIService.name
    simApiJson["sim"]["adapter_version"] = SimAPIService.adapter_version
    simApiJson["sim"]["simapi_version"] = SimAPIService.simapi_version
    simApiJson["sim"]["exe"] = SimAPIService.simulator_exe_title
    simApiJson["sim"]["variables"] = exportFields

    local file = io.open(SIMAPI_INPUT_FILE, "w")
    if file then
        file:write(json:encode(simApiJson))
        file:close()
    else
        logger.log("Failed to export simAPI_input.json file")

    end
end

function SimAPIService.getLatestCommmadsFromSimAPI()
    local commands = {}
    local fileAttributes = lfs.attributes(SIMAPI_OUTPUT_FILE)

    -- File does not exist, return empty commands
    if not fileAttributes then
        return commands
    end

    local modificationTime = fileAttributes.modification
    if lastSimAPIOutputTimestamp and modificationTime <= lastSimAPIOutputTimestamp then
        return commands
    end

    local simAPIOutputFile = io.open(SIMAPI_OUTPUT_FILE, "r")
    if simAPIOutputFile then
        for line in simAPIOutputFile:lines() do
            local obj, pos, err = json:decode(line)
            if obj then
                commands[obj['setvar']] = obj.value
            end
        end

        simAPIOutputFile:close()
        os.remove(SIMAPI_OUTPUT_FILE)
        lastSimAPIOutputTimestamp = modificationTime
    end
    
    return commands
end


return SimAPIService