local Progress <const> = lib.load('data.progress')
local Settings <const> = lib.load('data.vehicle')

local BONES <const> = {
    [0] =   'wheel_lf',
            'wheel_rf',
            'wheel_lm',
            'wheel_rm',
            'wheel_lr',
            'wheel_rr'
}

---@class privateHandlerData
---@field active boolean
---@field limited boolean
---@field control boolean
---@field oxfuel boolean
---@field electric boolean
---@field class number | false
---@field model number | false
---@field data table

---@class Handler : OxClass
---@field private private privateHandlerData
---@diagnostic disable-next-line: assign-type-mismatch
local Handler = lib.class('vehiclehandler')

function Handler:constructor()
    self:setActive(false)
    self:setLimited(false)
    self:setControl(true)
    self.private.oxfuel = GetResourceState('ox_fuel') == 'started' and true or false
end

---@return boolean active
function Handler:isActive() return self.private.active end

---@return boolean limited
function Handler:isLimited() return self.private.limited end

---@return boolean control
function Handler:canControl() return self.private.control end

---@return boolean oxfuel
function Handler:isFuelOx() return self.private.oxfuel end

---@return boolean electric
function Handler:isElectric() return self.private.electric end

---@return number | false class
function Handler:getClass() return self.private.class end

---@return number | false class
function Handler:getModel() return self.private.model end

---@param state string
---@return number | nil
function Handler:getData(state)
    if not state or type(state) ~= 'string' then return end

    return self.private.data[state]
end

---@return boolean isValid
function Handler:isValid()
    if not cache.ped then return false end
    if cache.vehicle or self.private.class == 16 then return true end

    return false
end

---@param vehicle number
---@param coords vector3
---@return boolean isTireBroken
function Handler:isTireBroken(vehicle, coords)
    if not vehicle or not coords then return false end

    for k,v in pairs(BONES) do
        local bone = GetEntityBoneIndexByName(vehicle, v)
        if bone == -1 then goto skip end

        if IsVehicleTyreBurst(vehicle, k, true) then
            local pos = GetWorldPositionOfEntityBone(vehicle, bone)

            if #(coords - pos) < 2.5 then
                return true
            end
        end

        ::skip::
    end

    return false
end

---@param state boolean
function Handler:setActive(state)
    if state ~= nil and type(state) == 'boolean' then
        self.private.active = state

        if state then
            self.private.class = GetVehicleClass(cache.vehicle) or false
            self.private.model = GetEntityModel(cache.vehicle)
            self.private.electric = GetIsVehicleElectric(self.private.model)
        else
            self.private.class = false
            self.private.model = false
            self.private.electric = false
            self.private.data = {['engine'] = 0, ['body'] = 0, ['speed'] = 0}
        end
    end
end

---@param state boolean
function Handler:setLimited(state)
    if state ~= nil and type(state) == 'boolean' then
        self.private.limited = state
    end
end

---@param state boolean
function Handler:setControl(state)
    if state ~= nil and type(state) == 'boolean' then
        self.private.control = state
    end
end

---@class handlerData
---@field engine number
---@field body number

---@param data handlerData
---@return number | nil engine
---@return number |nil body
---@return number | nil speed
function Handler:setData(data)
    if data == nil or type(data) ~= 'table' then return end

    self.private.data = data

    return data['engine'], data['body'], data['speed']
end

---@param vehicle number
---@return boolean | nil backengine
---@return vector3 | nil offset
---@return number | nil index
---@return number | nil engine
function Handler:getFixData(vehicle)
    if not vehicle or vehicle == 0 then return end

    local backengine = Settings.backengine[GetEntityModel(vehicle)]

    -- Stand just past the front (or back) bumper. Using the model's real size makes this work for
    -- every vehicle, from compacts to trucks, instead of a fixed distance from the vehicle's centre.
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local distance = backengine and (min.y - 0.5) or (max.y + 0.5)
    local offset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, distance, 0.0)

    -- 4 = hood, 5 = trunk. Bikes and some vehicles have neither, so only use the door if it exists.
    local index = backengine and 5 or 4
    if not GetIsDoorValid(vehicle, index) then index = nil end

    local engine = GetVehicleEngineHealth(vehicle)

    return backengine, offset, index, engine
end

---@param vehicle number
---@param index number
function Handler:breakTire(vehicle, index)
    if vehicle == nil or type(vehicle) ~= 'number' then return end
    if index == nil or type(index) ~= 'number' then return end

    local bone = GetEntityBoneIndexByName(vehicle, BONES[index])
    if bone == -1 then return end

    if not IsVehicleTyreBurst(vehicle, index, true) then

        lib.callback('vehiclehandler:sync', false, function()
            SetVehicleTyreBurst(vehicle, index, true, 1000.0)
            BreakOffVehicleWheel(vehicle, index, false, true, true, false)
        end)
    end
end

---@param vehicle number
---@param coords vector3
---@return boolean success
function Handler:fixTire(vehicle, coords)
    local found = self:isTireBroken(vehicle, coords)
    if not found then return false end

    local success = false

    TaskTurnPedToFaceEntity(cache.ped, vehicle, 1000)
    Wait(1000)

    if lib.progressCircle(Progress['tirekit']) then
        success = true
        self:applyKit(vehicle, 'tirekit')
    end

    return success
end

---@param vehicle number
---@param coords vector3
---@param fixtype string
---@return boolean success
function Handler:fixVehicle(vehicle, coords, fixtype)
    local backengine, offset, hoodindex, engine = self:getFixData(vehicle)
    local success = false

    if #(coords.xy - offset.xy) >= 2.0 then
        lib.notify({ title = locale(backengine and 'notify.backEngine' or 'notify.frontEngine'), type = 'error' })
        return success
    end

    if fixtype == 'smallkit' and engine >= 500 or fixtype == 'bigkit' and engine >= 1000 then
        lib.notify({ title = locale('notify.cannotRepair'), type = 'error' })
        return success
    end

    if hoodindex then
        lib.callback('vehiclehandler:sync', false, function()
            SetVehicleDoorOpen(vehicle, hoodindex, false, false)
        end)
    end

    -- Face the engine bay so the repair animation lines up with the vehicle
    TaskTurnPedToFaceEntity(cache.ped, vehicle, 1000)
    Wait(1000)

    if lib.progressCircle(Progress[fixtype]) then
        success = true
    end

    ClearPedTasks(cache.ped)

    if hoodindex then
        lib.callback('vehiclehandler:sync', false, function()
            SetVehicleDoorShut(vehicle, hoodindex, false)
        end)

        local timeout = GetGameTimer() + 3000
        repeat Wait(100)
        until not IsVehicleDoorFullyOpen(vehicle, hoodindex) or GetGameTimer() > timeout
    end

    if success then
        self:applyKit(vehicle, fixtype)
    end

    return success
end

---@param fixtype string
---@return boolean | nil success
---@return number | nil netId the repaired vehicle, so the server can sync the repair through its owner
function Handler:basicfix(fixtype)
    if not cache.ped then return false end
    if not fixtype or type(fixtype) ~= 'string' then return false end

    if cache.vehicle then
        lib.notify({ title = locale('notify.leaveVehicle'), type = 'error' })
        return false
    end

    -- Search wide enough to find long vehicles from their bumper; fixVehicle checks the exact spot
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 6.0, false)
    if vehicle == nil or vehicle == 0 then
        lib.notify({ title = locale('notify.noVehicle'), type = 'error' })
        return false
    end

    local success = false

    if fixtype == 'tirekit' then
        success = self:fixTire(vehicle, coords)
    elseif fixtype == 'smallkit' or fixtype == 'bigkit' then
        success = self:fixVehicle(vehicle, coords, fixtype)
    end

    if success then return true, VehToNet(vehicle) end

    return false
end

---Apply a repair kit's effect. Run on the player using the kit (instant feedback) and on the vehicle's
---network owner (sent by the server), so the repair syncs to everyone.
---@param vehicle number
---@param fixtype string
function Handler:applyKit(vehicle, fixtype)
    lib.callback('vehiclehandler:sync', false, function()
        if fixtype == 'tirekit' then
            local lastengine = GetVehicleEngineHealth(vehicle)
            local lastbody = GetVehicleBodyHealth(vehicle)
            local lastdirt = GetVehicleDirtLevel(vehicle)

            SetVehicleFixed(vehicle)
            SetVehicleEngineHealth(vehicle, lastengine)
            SetVehicleBodyHealth(vehicle, lastbody)
            SetVehicleDirtLevel(vehicle, lastdirt)
            return
        end

        if fixtype == 'smallkit' then
            if GetVehicleEngineHealth(vehicle) < 500 then
                SetVehicleEngineHealth(vehicle, 500.0)
            end

            if GetVehicleBodyHealth(vehicle) < 500 then
                SetVehicleBodyHealth(vehicle, 500.0)
            end
        elseif fixtype == 'bigkit' then
            SetVehicleFixed(vehicle)
        else
            return
        end

        SetVehicleUndriveable(vehicle, false)
    end)
end

---@return boolean success
---@return number | nil netId
function Handler:basicwash()
    if not cache.ped then return false end

    local pos = GetEntityCoords(cache.ped)
    local vehicle, vehpos = lib.getClosestVehicle(pos, 3.0, false)
	if vehicle == nil or vehicle == 0 then return false end

    if #(pos - vehpos) > 3.0 or cache.vehicle then return false end

    local success = false
    TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_MAID_CLEAN", 0, true)

    if lib.progressCircle(Progress['cleankit']) then
        success = true
        self:applyWash(vehicle)
    end

    ClearAllPedProps(cache.ped)
    ClearPedTasks(cache.ped)

    if success then return true, VehToNet(vehicle) end

    return false
end

---Repair and refuel a vehicle. Only syncs to other players when run on the vehicle's owner.
---@param vehicle number
function Handler:applyFix(vehicle)
    lib.callback('vehiclehandler:sync', false, function()
        SetVehicleFixed(vehicle)
        ResetVehicleWheels(vehicle, true)

        if self:isFuelOx() then
            Entity(vehicle).state.fuel = 100.0
        end

        SetVehicleFuelLevel(vehicle, 100.0)
        DecorSetFloat(vehicle, '_FUEL_LEVEL', GetVehicleFuelLevel(vehicle))

        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, true)
    end)
end

---Clean a vehicle. Only syncs to other players when run on the vehicle's owner.
---@param vehicle number
function Handler:applyWash(vehicle)
    lib.callback('vehiclehandler:sync', false, function()
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
    end)
end

---@return boolean success
function Handler:adminfix()
    if not self:isValid() then return false end

    local success = lib.callback.await('ox_lib:checkPlayerAce', false, 'command.fix')

    if success then
        self:applyFix(cache.vehicle)
    end

    return success
end

---@return boolean success
function Handler:adminwash()
    if not self:isValid() then return false end

    local success = lib.callback.await('ox_lib:checkPlayerAce', false, 'command.wash')

    if success then
        self:applyWash(cache.vehicle)
    end

    return success
end

---@param newlevel number
---@return boolean success
function Handler:adminfuel(newlevel)
    if not self:isValid() then return false end
    if not newlevel then return false end

    local success = lib.callback.await('ox_lib:checkPlayerAce', false, 'command.setfuel')

    if success then
        self:applyFuel(cache.vehicle, lib.math.clamp(newlevel, 0.0, 100.0) + 0.0)
    end

    return success
end

---Set a vehicle's fuel level in this game. Only syncs to other players when run on the vehicle's owner
---(the server sets ox_fuel's replicated state).
---@param vehicle number
---@param newlevel number
function Handler:applyFuel(vehicle, newlevel)
    lib.callback('vehiclehandler:sync', false, function()
        if self:isFuelOx() then
            Entity(vehicle).state.fuel = newlevel
        end

        SetVehicleFuelLevel(vehicle, newlevel)
        DecorSetFloat(vehicle, '_FUEL_LEVEL', GetVehicleFuelLevel(vehicle))

        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, true)
    end)
end

return Handler