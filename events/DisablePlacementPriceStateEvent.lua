-- Send request to Server to alter disablePlacementPrice state
--
-- Client => DisablePlacementPriceStateEvent -> Server => broadcast PlaceAnywhereStateEvent if changed

---@class DisablePlacementPriceStateEvent
DisablePlacementPriceStateEvent = {}

local DisablePlacementPriceStateEvent_mt = Class(DisablePlacementPriceStateEvent, Event)

InitEventClass(DisablePlacementPriceStateEvent, 'DisablePlacementPriceStateEvent')

function DisablePlacementPriceStateEvent:emptyNew()
    return Event:new(DisablePlacementPriceStateEvent_mt)
end

---@param enabled boolean
function DisablePlacementPriceStateEvent:new(enabled)
    local self = DisablePlacementPriceStateEvent:emptyNew()
    self.enabled = enabled
    return self
end

---@param streamId number
---@param connection Connection
function DisablePlacementPriceStateEvent:readStream(streamId, connection)
    self.enabled = streamReadBool(streamId)
    self:run(connection)
end

---@param streamId number
---@param connection Connection
function DisablePlacementPriceStateEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enabled)
end

---@param connection Connection
function DisablePlacementPriceStateEvent:run(connection)
    -- Only process event on server side
    if not connection:getIsServer() then
        local user = g_currentMission.userManager:getUserByConnection(connection)

        if user == nil then
            print('unknown user')
            return
        end

        -- Limit state altering to master user(s) (admin)
        if user:getIsMasterUser() then
            PlaceAnywhere.disablePlacementPrice = self.enabled

            PlaceAnywhere.broadcastState()
        else
            print(('Player %s tried to change disablePlacementPrice, but does not have access (MasterUser)'):format(user:getNickname()))
            PlaceAnywhere.sendErrorEvent(connection, 0, 'Access denied')
        end
    end
end