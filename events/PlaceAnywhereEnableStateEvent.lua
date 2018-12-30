-- Send request to Server to alter enablePlaceAnywhere state
--
-- Client => PlaceAnywhereEnableStateEvent -> Server => broadcast PlaceAnywhereStateEvent if changed

---@class PlaceAnywhereEnableStateEvent
PlaceAnywhereEnableStateEvent = {}

local PlaceAnywhereEnableStateEvent_mt = Class(PlaceAnywhereEnableStateEvent, Event)

InitEventClass(PlaceAnywhereEnableStateEvent, 'PlaceAnywhereEnableStateEvent')

function PlaceAnywhereEnableStateEvent:emptyNew()
    return Event:new(PlaceAnywhereEnableStateEvent_mt)
end

---@param state boolean
function PlaceAnywhereEnableStateEvent:new(state)
    local self = PlaceAnywhereEnableStateEvent:emptyNew()
    self.state = state
    return self
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereEnableStateEvent:readStream(streamId, connection)
    self.state = streamReadBool(streamId)
    self:run(connection)
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereEnableStateEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.state)
end

---@param connection Connection
function PlaceAnywhereEnableStateEvent:run(connection)
    if not connection:getIsServer() then
        local user = g_currentMission.userManager:getUserByConnection(connection)

        if user == nil then
            print('unknown user')
            return
        end

        -- Limit state altering to master user(s) (admin)
        if user:getIsMasterUser() then
            PlaceAnywhere.enablePlaceAnywhere = self.state
            PlaceAnywhere.broadcastState()
        else
            print(('Player %s tried to change enablePlaceAnywhere, but does not have access (MasterUser)'):format(user:getNickname()))
            PlaceAnywhere.sendErrorEvent(connection, 0, 'Access denied')
        end
    end
end