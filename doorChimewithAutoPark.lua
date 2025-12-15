--Made by Strict

local M = {}
local volumeDoor, pitchDoor = 4, 1 --Change first value to your desired volume (decimals can be used) for door chime volume
local volumeBrake, pitchBrake = 4, 1 --Change first value to your desired volume (decimals can be used) for brake chime volume
local camNode = 0
-- chime state
local timer = 0
local lastDoorState = false
local doorChimePlaying = false
local brakeChimePlaying = false
local nextDoorChimeTime = 0
local nextBrakeChimeTime = 0
local brakeChimeDuration = 1 --Changes the speed that the chime plays (decimals can be used)
local doorChimeDuration = 1 --Changes the speed that the chime plays (decimals can be used)
-- pause logic
local skipChimeUntil = 0
local pauseDuration = 6.5 -- seconds to wait for ignition chime to end (change based on ignition chime configuration)
local lastIgnitionLevel = 0

-- Track if we engaged the parking brake so we can release it later
local softBrakeEngaged = false

local function inside()
    local cam = obj:getCameraPosition()
    local seat = obj:getPosition() + obj:getNodePosition(camNode)
    return cam and seat and cam:distance(seat) <= 0.6
end

local function update(dt)
    -- Door / trunk / hood check
    local anyDoorOpen = (electrics.values['door_FL_coupler_notAttached'] == 1 or --If vehicle is a coupe use L and R instead of FL and FR (RL and RR can be removed unless used differently on model)
                         electrics.values['door_FR_coupler_notAttached'] == 1 or 
                         electrics.values['door_RL_coupler_notAttached'] == 1 or 
                         electrics.values['door_RR_coupler_notAttached'] == 1 or
                         electrics.values['trunkCoupler_notAttached'] == 1 or  --Can use trunk or tailgate (depending on what vehicle has), if vehicle has both then keep both in file
                         electrics.values['tailgateCoupler_notAttached'] == 1 or  
                         electrics.values['hoodLatchCoupler_notAttached'] == 1)

    local ignitionLevel = electrics.values['ignitionLevel'] or 0
    local lightsState = electrics.values['lights_state'] or 0
    local lightsOn = (lightsState == 1 or lightsState == 2)

    -- Detect starter active (ignition 3 = crank)
    local isStarting = (ignitionLevel == 3)

    -- Detect when engine changes from starting to started (ignition 3 -> 2)
    if (lastIgnitionLevel == 3 and ignitionLevel == 2) or (lastIgnitionLevel == 1 and ignitionLevel == 2) then
        skipChimeUntil = timer + pauseDuration
    end
    lastIgnitionLevel = ignitionLevel

    -- Door chime logic
    local doorChimeActive = false
    if ignitionLevel > 1 then
        -- Normal ON/START behavior
        doorChimeActive = anyDoorOpen
    elseif ignitionLevel == 1 then
        -- Accessory: only if lights are on
        doorChimeActive = anyDoorOpen and lightsOn
    end

    -- Parking brake + throttle + gear check
    local parkingBrakeOn = (electrics.values.parkingbrake_input or 0) > 0.01
    local throttle = electrics.values.throttle or 0
    local gear = electrics.values.gearIndex or 0
    local inGear = (gear > 0) or (gear < 0) -- drive or reverse, not neutral/park

    local brakeChimeActive = (ignitionLevel > 0) and parkingBrakeOn and throttle > 0.05 and inGear

    -- Combined logic
    local chimeActive = doorChimeActive or brakeChimeActive

    -- Stops chime during crank and until ignition chime ends
    local suppressed = isStarting or (timer < skipChimeUntil)

    if inside() then
        -- Door Chime
        if doorChimeActive and not suppressed then
            if not doorChimePlaying then
                obj:playSFXOnce("YourVehicleDoorChime.wav", camNode, volumeDoor, pitchDoor)  -- change files to be door chime sounds
                doorChimePlaying = true
                nextDoorChimeTime = timer + doorChimeDuration
            elseif timer >= nextDoorChimeTime then
                obj:playSFXOnce("YourVehicleDoorChime.wav", camNode, volumeDoor, pitchDoor) --same as above
                nextDoorChimeTime = timer + doorChimeDuration
            end
        else
            doorChimePlaying = false
        end

        -- Brake chime
        if brakeChimeActive and not suppressed then
            if not brakeChimePlaying then
                obj:playSFXOnce("YourVehicleBrakeChime.wav", camNode, volumeBrake, pitchBrake) --change files to match desired WAV file (either same as door chime or seperate brake sound)
                brakeChimePlaying = true
                nextBrakeChimeTime = timer + brakeChimeDuration
            elseif timer >= nextBrakeChimeTime then
                obj:playSFXOnce("YourVehicleBrakeChime.wav", camNode, volumeBrake, pitchBrake) --same as above
                nextBrakeChimeTime = timer + brakeChimeDuration
            end
        else
            brakeChimePlaying = false
        end
    else
        doorChimePlaying = false
        brakeChimePlaying = false
    end

    timer = timer + dt
    lastDoorState = chimeActive

    -- Auto "soft" parking brake logic
    local vehicleSpeed = obj:getVelocity():length() * 2.23694  -- m/s to mph

    -- If door is open and speed <= 10 mph, engage parking brake softly
    if anyDoorOpen and vehicleSpeed <= 10 and not parkingBrakeOn and not softBrakeEngaged then
        if electrics and electrics.set_switch then
            electrics.set_switch("parkingbrake", 1)
            softBrakeEngaged = true
        elseif input and input.event then
            input.event("parkingbrake", 1)
            softBrakeEngaged = true
        end

        -- Show in-game popup warning
        if guihooks and guihooks.message then
            guihooks.message("Vehicle not in Park... Parking Brake Applied", 5, "important")
        end
    end

    -- If we applied the brake and driver taps gas, release it
    if softBrakeEngaged and throttle > 0.1 then
        if electrics and electrics.set_switch then
            electrics.set_switch("parkingbrake", 0)
            softBrakeEngaged = false
        elseif input and input.event then
            input.event("parkingbrake", 0)
            softBrakeEngaged = false
        end
    end
end

local function init()
    camNode = beamstate.nodeNameMap["driver"] or 0
    obj:createSFXSource("/art/sound/YourVehicle/YourVehicleDoorChime.wav", "Audio2D", "YourVehicleDoorChime.wav", -1) --Change File Names
--    obj:createSFXSource("/art/sound/YourVehicle/YourVehicleBrakeChime.wav", "Audio2D", "YourVehicleBrakeChime.wav", -1) --Change File Names and uncomment if you wish to use a different sound for the parking brake warning
end

M.onInit = init
M.updateGFX = update
return M