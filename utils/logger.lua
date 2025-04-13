local dcs_si_lfs=require('lfs')
local Logger = {}

local logFilePath = dcs_si_lfs.writedir().."Logs/SayIntentionsAdapter.log"

function Logger.log(message)
    local file = io.open(logFilePath, "a")
    if file then
        file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. message .. "\n")
        file:close()
    else
        env.error("Logger.lua: Could not open file: " .. Logger.logFilePath)
    end
end

return Logger
