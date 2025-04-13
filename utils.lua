local utils = {}

utils.SayIntetionsEngineTypes = {
    Piston = 0,
    Jet = 1,
    None = 2,
    TurbineHelicopter = 3,
    Unsupported = 4,
    Turboprop = 5
}

function utils.mpsToKnots(mps)
    return mps * 1.943844
end

function utils.radToDeg(rad)
    return rad * (180 / math.pi)
end

function utils.metersToFeet(meters)
    return meters * 3.28084
end

function utils.metersPerSecondToFeetPerMinute(mps)
    return mps * 3.28084 * 60
end

function utils.kgToLbs(kg)
    return kg * 2.20462
end

function utils.frequencyToRadioChannel(frequncy)
    local khzFreq = math.floor(frequncy / 1000)
    return (math.floor(khzFreq / 5) * 5) / 1000
end

function utils.vectorToWind(vector)
    local horizontalSpeed = math.sqrt(vector.x^2 + vector.y^2)
    local windSpeed = math.sqrt(vector.x^2 + vector.y^2 + vector.z^2) * 1.943844 -- Convert m/s to knots

    local windDirection = math.deg(math.atan2(vector.y, vector.x)) + 180 -- Opposite direction
    windDirection = (windDirection + 360) % 360 -- Ensure 0-360 range

    return windDirection, windSpeed
end

function utils.tableToString(tbl, indent)
	indent = indent or 2
	local result = ""
	local formatting = string.rep("  ", indent)
	for key, value in pairs(tbl) do
		if type(value) == "table" then
			result = result .. formatting .. tostring(key) .. ":\n"
			result = result .. ufcPatch.tableToString(value, indent + 1)  -- Recursive call for nested tables
		else
			result = result .. formatting .. tostring(key) .. " = " .. tostring(value) .. "\n"
		end
	end
	return result
end

function utils.getDCSListIndication(indicator_id)
    local ret = {}
    local li = list_indication(indicator_id)
    if li == "" then return nil end
    local m = li:gmatch("-----------------------------------------\n([^\n]+)\n([^\n]*)\n")
    while true do
        local name, value = m()
        if not name then
            break
        end
        ret[name] = value
    end
    return ret
end

function utils.calculateWheelRPMFromKnotsAndRadius(speed_knots, radius_in)
    local inches_per_minute = speed_knots * 1.68781 * 12 * 60
    local circumference = 2 * math.pi * radius_in
    local rpm = inches_per_minute / circumference
    return rpm
end


return utils
