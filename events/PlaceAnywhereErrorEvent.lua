---@class PlaceAnywhereErrorEvent
PlaceAnywhereErrorEvent = {}

local PlaceAnywhereErrorEvent_mt = Class(PlaceAnywhereErrorEvent, Event)

InitEventClass(PlaceAnywhereErrorEvent, 'PlaceAnywhereErrorEvent')

function PlaceAnywhereErrorEvent:emptyNew()
    return Event:new(PlaceAnywhereErrorEvent_mt)
end

---@param code number
---@param message string
function PlaceAnywhereErrorEvent:new(code, message)
    local self = PlaceAnywhereErrorEvent:emptyNew()
    self.code = code or 0
    self.message = message or 'Unknown error'
    return self
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereErrorEvent:readStream(streamId, connection)
    self.code = streamReadUInt8(streamId)
    self.message = streamReadString(streamId)
    self:run(connection)
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereErrorEvent:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.code)
    streamWriteString(streamId, self.message)
end

---@param connection Connection
function PlaceAnywhereErrorEvent:run(connection)
    -- Only process event on client side
    if connection:getIsServer() then
        PlaceAnywhere.onErrorEvent(self.code, self.message)
    end
end