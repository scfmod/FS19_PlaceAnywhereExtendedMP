-- Send request to Server to alter dismissTerrainDeformation state
--
-- Client => DismissTerrainDeformationStateEvent -> Server => broadcast PlaceAnywhereStateEvent if changed

---@class DismissTerrainDeformationStateEvent
DismissTerrainDeformationStateEvent = {}

local DismissTerrainDeformationStateEvent_mt = Class(DismissTerrainDeformationStateEvent, Event)

InitEventClass(DismissTerrainDeformationStateEvent, 'DismissTerrainDeformationStateEvent')

function DismissTerrainDeformationStateEvent:emptyNew()
    return Event:new(DismissTerrainDeformationStateEvent_mt)
end

---@param enabled boolean
function DismissTerrainDeformationStateEvent:new(enabled)
    local self = DismissTerrainDeformationStateEvent:emptyNew()
    self.enabled = enabled
    return self
end

---@param streamId number
---@param connection Connection
function DismissTerrainDeformationStateEvent:readStream(streamId, connection)
    self.enabled = streamReadBool(streamId)
    self:run(connection)
end

---@param streamId number
---@param connection Connection
function DismissTerrainDeformationStateEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enabled)
end

---@param connection Connection
function DismissTerrainDeformationStateEvent:run(connection)
    -- Only process event on server side
    if not connection:getIsServer() then
        local user = g_currentMission.userManager:getUserByConnection(connection)

        if user == nil then
            print('unknown user')
            return
        end

        -- Limit state altering to master user(s) (admin) or if user is farm manager
        if user:getIsMasterUser() or playerHasPermission(user.userId, 'manageRights') then
            PlaceAnywhere.dismissTerrainDeformation = self.enabled
            PlaceAnywhere.broadcastState()
        else
            print(('Player %s tried to change dismissTerrainDeformation, but does not have access (MasterUser|manageRights)'):format(user:getNickname()))
            PlaceAnywhere.sendErrorEvent(connection, 0, 'Access denied')
        end
    end
end