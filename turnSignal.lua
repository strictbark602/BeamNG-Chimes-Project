local M = {}
local volume, pitch = 4, 1
local camNode = 0
local wasOn = false

--Section only required if using delay
local timer = 0
local lastIgnitionLevel = 0
local skipSignalUntil = 0
local pauseSignalDuration = 5 --amount of seconds for delay (set to 0 if you dont want a delay)
--

local function inside()
    local cam = obj:getCameraPosition()
    local seat = obj:getPosition() + obj:getNodePosition(camNode)
    return cam and seat and cam:distance(seat) <= 1.6
end

local function update(dt)
    --Reads ignition level
    local ignitionLevel = electrics.values['ignitionLevel'] or 0

    --Detect starter active (ignition 3 = crank)
    local isStarting = (ignitionLevel == 3)

    --Detect when engine changes from starting to started (ignition 3 -> 2)

    if (lastIgnitionLevel == 3 and ignitionLevel == 2) or (lastIgnitionLevel == 1 and ignitionLevel == 2) then
        skipSignalUntil = timer + pauseSignalDuration
    end
    lastIgnitionLevel = ignitionLevel

    --Stops signal during crank and until ignition chime ends
    local suppressed = isStarting or (timer < skipSignalUntil)

    local isOn = electrics.values.signal_L == 1 or electrics.values.signal_R == 1
    --if using a pause add "and not suppressed" between inside() and isOn, do NOT include the quotation marks
    if inside() and not suppressed and isOn ~= wasOn then
        obj:playSFXOnce(isOn and "template_on.wav" or "template_off.wav", camNode, volume, pitch) --Change file names
    end
    wasOn = isOn
    timer = timer + dt --Can be removed if you are not using the delay
end

local function init()
    camNode = beamstate.nodeNameMap["driver"] or 0
    obj:createSFXSource("/art/sound/sample/template_on.wav", "Audio2D", "template_on.wav", -1) --Change directory and names
    obj:createSFXSource("/art/sound/sample/template_off.wav", "Audio2D", "template_off.wav", -1) --Change directory and names
end

M.onInit = init
M.updateGFX = update
return M