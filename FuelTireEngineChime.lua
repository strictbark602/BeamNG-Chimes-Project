--Made by Strict
local M = {}

local camNode = 0
local volume, pitch = 4, 1
local fuelChimePlayed = false
local tireChimePlayed = false
local engineChimePlayed = false
local coolantChimePlayed = false
local lowOilChimePlayed = false
local internalDamageChimePlayed = false
local lastFuelLevel = 1
local lowFuelThreshold = 0.10
local lowTirePressureThreshold = 15 -- psi
local spawnedRecently = true
local spawnTimer = 0
local spawnCooldown = 1.5 -- seconds
local overheatCoolantTemp = 120 --degrees celcius for overheat coolant temp
local overheatOilTemp = 130 --degrees celcius for overheat oil temp

-- Check if camera is inside (driver view)
local function inside()
    local cam = obj:getCameraPosition()
    local seat = obj:getPosition() + obj:getNodePosition(camNode)
    return cam and seat and cam:distance(seat) <= 0.6
end

-- Determine if a tire is flat, destroyed, low pressure, or broken
local function isTireBad(wheel)
    if not wheel then return false end
    return wheel.tireState == "deflated"
        or wheel.tireState == "destroyed"
        or (wheel.pressure or 999) < lowTirePressureThreshold
        or wheel.isBroken == true
end

local function update(dt)
    -- Delay after spawn/reset
    if spawnedRecently then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnCooldown then
            spawnedRecently = false
        else
            return
        end
    end

    if not inside() then return end

    -- Fuel chime logic
    local ignitonLevel = electrics.values['ignitionLevel']
    local engineOn = ignitonLevel >= 1
    local fuelLevel = electrics.values.fuel or 1
    if not fuelChimePlayed and engineOn and lastFuelLevel >= lowFuelThreshold and fuelLevel <= lowFuelThreshold then
        obj:playSFXOnce("YourVehicleChime.wav", camNode, volume, pitch)
        fuelChimePlayed = true
    elseif not (lastFuelLevel >= lowFuelThreshold) and fuelLevel <= lowFuelThreshold then
        fuelChimePlayed = false
    end
    lastFuelLevel = fuelLevel

    -- Tire check across all wheels
    local anyTireBad = false
    for i = 0, 3 do
        local wheel = wheels.wheels[i]
        if isTireBad(wheel) then
            anyTireBad = true
            break
        end
    end

    if anyTireBad and not tireChimePlayed then
        obj:playSFXOnce("YourVehicleChime.wav", camNode, volume, pitch)  -- Change file name
        tireChimePlayed = true
    end
        -- Radiator Leak / Overheating (Universal ICE + EV)
    local engineType = powertrain.getDevice("mainEngine") --Bug fix for EVs, this code only activates if the engine is gas
    local storages = energyStorage.getStorages()
    local isElectric = false
    for _, storage in pairs(storages) do
        if storage.type == "electricBattery" then
            isElectric = true
            break
        end
    end

    if engineType and not isElectric then
        local coolantTemp = powertrain.getDevice("mainEngine").thermals.coolantTemperature or powertrain.getDevice("mainMotor").thermals.motorTemperature
        local radiatorLeak = damageTracker.getDamage('engine', 'radiatorLeak')
        local radiatorDamage = (radiatorLeak or coolantTemp > overheatCoolantTemp)
         if radiatorDamage and not coolantChimePlayed then
            obj:playSFXOnce("YourVehicleChime.wav", camNode, volume, pitch) --Change file name
            coolantChimePlayed = true
        elseif not radiatorDamage then
            coolantChimePlayed = false
        end
    
        --Starved of Oil
        local starvedOil = damageTracker.getDamage('engine', 'starvedOfOil')
        local oilTemp = powertrain.getDevice("mainEngine").thermals.oilTemperature
        local highOilTemp = (oilTemp > overheatOilTemp )
        local critialOil = damageTracker.getDamage('engine', 'oilLevelCritical')
        local starvedOfOil = (starvedOil or critialOil or highOilTemp)
        if starvedOfOil and not lowOilChimePlayed then
            obj:playSFXOnce("YourVehicleChime.wav", camNode, volume, pitch) --Change file name
            lowOilChimePlayed = true
        elseif not starvedOfOil then
            lowOilChimePlayed = false
        end
        --Internal Engine Damage
        local pistonRingDamaged = damageTracker.getDamage('engine', 'pistonRingsDamaged')
        local inductionSystemDamaged = damageTracker.getDamage('engine', 'inductionSystemDamaged')
        local internalDamage = (pistonRingDamaged or inductionSystemDamaged)
        if internalDamage and not internalDamageChimePlayed then
            obj:playSFXOnce("YourVehicleChime.wav", camNode, volume, pitch)  --Change file name
            internalDamageChimePlayed = true
        elseif not internalDamage then
            internalDamageChimePlayed = false
        end


        -- Engine (powertrain) failure chime
        local engine = powertrain.getDevice("mainEngine") or 0
        if engine then
            local engineBroken = engine.isBroken or (engine.damage and engine.damage > 0.99)
            if engineBroken and not engineChimePlayed then
                obj:playSFXOnce("YourVehicleChime.wav", camNode, volume, pitch)  --Change file name
                engineChimePlayed = true
            elseif not engineBroken then
                engineChimePlayed = false
            end
        end
    end
end

local function init()
    camNode = beamstate and beamstate.nodeNameMap and beamstate.nodeNameMap["driver"] or 0
    obj:createSFXSource("/art/sound/YourVehicle/YourVehicleChime.wav", "Audio2D", "YourVehicleChime.wav", -1)  --Change directory and file name
    -- addition audio lines can be added if you want to have different alert sounds for the different types of damages or conditions above
    fuelChimePlayed = false
    tireChimePlayed = false
    engineChimePlayed = false
    lastFuelLevel = electrics.values.fuel or 1
    coolantChimePlayed = false
    lowOilChimePlayed = false
    internalDamageChimePlayed = false
    spawnedRecently = true
    spawnTimer = 0
end

local function onReset()
    fuelChimePlayed = false
    tireChimePlayed = false
    engineChimePlayed = false
    lastFuelLevel = electrics.values.fuel or 1
    coolantChimePlayed = false
    lowOilChimePlayed = false
    internalDamageChimePlayed = false
    spawnedRecently = true
    spawnTimer = 0
end

M.onInit = init
M.onReset = onReset
M.updateGFX = update
return M