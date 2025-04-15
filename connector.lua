local lfs = require('lfs')
package.path = package.path .. ";" .. lfs.writedir() .. "Scripts\\SayIntentions\\?.lua"

local logger = require("utils//logger")
local SimAPIService = require("SimAPIService")
local moduleManager = require("aircraft//ModuleManager")

local SayIntentions = {}

function SayIntentions.processSimAPIExport()
    local moduleExportFields = moduleManager.getExportFields()
    local moduleName = moduleManager.currentModuleName
    SimAPIService.writeExportFile(moduleExportFields, moduleName)
end

function SayIntentions.processSimAPIInputs()
    local latestCommands = SimAPIService.getLatestCommmadsFromSimAPI()
    moduleManager.processSimAPICommands(latestCommands)
end

function SayIntentions.init()
    SimAPIService.initalize()
    logger.log("SayIntentions Export Script Loaded.")
end

function SayIntentions.update()
    moduleManager.update()

    if moduleManager.currentModule then
        SayIntentions.processSimAPIExport()
        SayIntentions.processSimAPIInputs()
    else
        logger.log("Can not find current aircraft module")
    end
end

function SayIntentions.stop()
    logger.log("SayIntentions Export Script Stopping.")
end

local SayIntentionsExport = {}
SayIntentionsExport.LuaExportStart              = LuaExportStart
SayIntentionsExport.LuaExportStop               = LuaExportStop
SayIntentionsExport.LuaExportBeforeNextFrame    = LuaExportBeforeNextFrame
SayIntentionsExport.LuaExportAfterNextFrame     = LuaExportAfterNextFrame
SayIntentionsExport.LuaExportActivityNextEvent  = LuaExportActivityNextEvent

function LuaExportStart()
    SayIntentions.init()
    if SayIntentionsExport.LuaExportStart then
        SayIntentionsExport.LuaExportStart()
    end
end

function LuaExportStop()
    SayIntentions.stop()

    if SayIntentionsExport.LuaExportStop then
        SayIntentionsExport.LuaExportStop()
    end
end

function LuaExportActivityNextEvent(t)
    SayIntentions.update()
    return t + 1.0
end

function LuaExportBeforeNextFrame()
    if SayIntentionsExport.LuaExportBeforeNextFrame then
        SayIntentionsExport.LuaExportBeforeNextFrame()
    end
end

function LuaExportAfterNextFrame()
    if SayIntentionsExport.LuaExportAfterNextFrame then
        SayIntentionsExport.LuaExportAfterNextFrame()
    end
end
