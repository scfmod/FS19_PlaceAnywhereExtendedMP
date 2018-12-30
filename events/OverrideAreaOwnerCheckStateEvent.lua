-- Send request to Server to alter overrideAreaOwnerCheck state
--
-- Client => OverrideAreaOwnerCheckStateEvent -> Server => broadcast PlaceAnywhereStateEvent if changed

---@class OverrideAreaOwnerCheckStateEvent
OverrideAreaOwnerCheckStateEvent = {}

local OverrideAreaOwnerCheckStateEvent_mt = Class(OverrideAreaOwnerCheckStateEvent, Event)

InitEventClass(OverrideAreaOwnerCheckStateEvent, 'OverrideAreaOwnerCheckStateEvent')

function OverrideAreaOwnerCheckStateEvent:emptyNew()
    return Event:new(OverrideAreaOwnerCheckStateEvent_mt)
end

---@param enabled boolean
function OverrideAreaOwnerCheckStateEvent:new(enabled)
    local self = OverrideAreaOwnerCheckStateEvent:emptyNew()
    self.enabled = enabled
    return self
end

---@param streamId number
---@param connection Connection
function OverrideAreaOwnerCheckStateEvent:readStream(streamId, connection)
    self.enabled = streamReadBool(streamId)
    self:run(connection)
end

---@param streamId number
---@param connection Connection
function OverrideAreaOwnerCheckStateEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enabled)
end

---@param connection Connection
function OverrideAreaOwnerCheckStateEvent:run(connection)
    -- Only process event on client side
    if not connection:getIsServer() then
        local user = g_currentMission.userManager:getUserByConnection(connection)

        if user == nil then
            print('unknown user')
            return
        end

        -- Limit state altering to master user(s) (admin)
        if user:getIsMasterUser() then
            PlaceAnywhere.overrideAreaOwnerCheck = self.enabled
            PlaceAnywhere.broadcastState()
        else
            print(('Player %s tried to change overrideAreaOwnerCheck, but does not have access (MasterUser)'):format(user:getNickname()))
            PlaceAnywhere.sendErrorEvent(connection, 0, 'Access denied')
        end
    end
end
