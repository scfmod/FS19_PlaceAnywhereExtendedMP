-- Send state data to client(s)

---@class PlaceAnywhereStateEvent
PlaceAnywhereStateEvent = {}

local PlaceAnywhereStateEvent_mt = Class(PlaceAnywhereStateEvent, Event)

InitEventClass(PlaceAnywhereStateEvent, 'PlaceAnywhereStateEvent')

function PlaceAnywhereStateEvent:emptyNew()
    return Event:new(PlaceAnywhereStateEvent_mt)
end

---@param enablePlaceAnywhere boolean
---@param overrideAreaOwnerCheck boolean
---@param dismissTerrainDeformation boolean
---@param disablePlacementPrice boolean
function PlaceAnywhereStateEvent:new(enablePlaceAnywhere, overrideAreaOwnerCheck, dismissTerrainDeformation, disablePlacementPrice)
    local self = PlaceAnywhereStateEvent:emptyNew()
    self.enablePlaceAnywhere = enablePlaceAnywhere
    self.overrideAreaOwnerCheck = overrideAreaOwnerCheck
    self.dismissTerrainDeformation = dismissTerrainDeformation
    self.disablePlacementPrice = disablePlacementPrice
    return self
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereStateEvent:readStream(streamId, connection)
    self.enablePlaceAnywhere = streamReadBool(streamId)
    self.overrideAreaOwnerCheck = streamReadBool(streamId)
    self.dismissTerrainDeformation = streamReadBool(streamId)
    self.disablePlacementPrice = streamReadBool(streamId)
    self:run(connection)
end

---@param streamId number
---@param connection Connection
function PlaceAnywhereStateEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enablePlaceAnywhere)
    streamWriteBool(streamId, self.overrideAreaOwnerCheck)
    streamWriteBool(streamId, self.dismissTerrainDeformation)
    streamWriteBool(streamId, self.disablePlacementPrice)
end

---@param connection Connection
function PlaceAnywhereStateEvent:run(connection)
    -- Only process event on client side
    if connection:getIsServer() then
        PlaceAnywhere.enablePlaceAnywhere = self.enablePlaceAnywhere
        PlaceAnywhere.overrideAreaOwnerCheck = self.overrideAreaOwnerCheck
        PlaceAnywhere.dismissTerrainDeformation = self.dismissTerrainDeformation
        PlaceAnywhere.disablePlacementPrice = self.disablePlacementPrice

        if PlaceAnywhere.disablePlacementPrice then
            PlacementScreenController.DISPLACEMENT_COST_PER_M3 = 0
        else
            PlacementScreenController.DISPLACEMENT_COST_PER_M3 = 50
        end
    end
end