local lfs = require('lfs')
package.path = package.path .. ";" .. lfs.writedir() .. "Scripts\\SayIntentions\\?.lua"

-- Imports
local logger = require("utils//logger")
local SimAPIService = require("SimAPIService")
local moduleManager = require("aircraft//ModuleManager")

--------------------------------------------------------------------------------
-- SayIntentions Commands
--------------------------------------------------------------------------------
local function processSimAPIExport()
    local moduleExportFields = moduleManager.getExportFields()
    local moduleName = moduleManager.currentModuleName
    SimAPIService.writeExportFile(moduleExportFields, moduleName)
end

local function processSimAPIInputs()
    local latestCommands = SimAPIService.getLatestCommmadsFromSimAPI()
    moduleManager.processSimAPICommands(latestCommands)
end

--------------------------------------------------------------------------------
-- DCS Export Functions
--------------------------------------------------------------------------------
function LuaExportStart()
    SimAPIService.initalize()
    logger.log("Export Script Loaded.")
end

function LuaExportActivityNextEvent(timestamp)
    moduleManager.update()

    if moduleManager.currentModule then
        processSimAPIExport()
        processSimAPIInputs()
    else
        logger.log("Can not find current aircraft module")
    end

    return timestamp + 1.0
end

function LuaExportStop()
    logger.log("Export Script Stopping.")
end
