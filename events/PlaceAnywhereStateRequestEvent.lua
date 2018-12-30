-- Request state data from Server event (no data sent in event)
--
-- Client => PlaceAnywhereStateRequestEvent -> Server => PlaceAnywhereStateEvent -> Client

---@class PlaceAnywhereStateRequestEvent
PlaceAnywhereStateRequestEvent = {}

local PlaceAnywhereStateRequestEvent_mt = Class(PlaceAnywhereStateRequestEvent, Event)

InitEventClass(PlaceAnywhereStateRequestEvent, 'PlaceAnywhereStateRequestEvent')

function PlaceAnywhereStateRequestEvent:emptyNew()
    return Event:new(PlaceAnywhereStateRequestEvent_mt)
end

function PlaceAnywhereStateRequestEvent:new()
    return PlaceAnywhereStateRequestEvent:emptyNew()
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereStateRequestEvent:readStream(streamId, connection)
    self:run(connection)
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereStateRequestEvent:writeStream(streamId, connection)
end

---@param connection Connection
function PlaceAnywhereStateRequestEvent:run(connection)
    -- Only process event on server side
    if not connection:getIsServer() then
        PlaceAnywhere.sendStateEvent(connection)
    end
end