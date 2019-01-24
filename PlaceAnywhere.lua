-- PlaceAnywhere Extended MP mod
-- Based on PlaceAnywhere mod 1.2.0.0 by naPalm
-- Extended MP version by estyx

PlaceAnywhere = {
    enablePlaceAnywhere = false,
    overrideAreaOwnerCheck = false,
    dismissTerrainDeformation = false,
    disablePlacementPrice = false,
};

getfenv(0)['PlaceAnywhere'] = PlaceAnywhere

source(g_currentModDirectory .. 'events/PlaceAnywhereErrorEvent.lua')
source(g_currentModDirectory .. 'events/PlaceAnywhereStateEvent.lua')
source(g_currentModDirectory .. 'events/PlaceAnywhereStateRequestEvent.lua')
source(g_currentModDirectory .. 'events/PlaceAnywhereEnableStateEvent.lua')
source(g_currentModDirectory .. 'events/OverrideAreaOwnerCheckStateEvent.lua')
source(g_currentModDirectory .. 'events/DismissTerrainDeformationStateEvent.lua')
source(g_currentModDirectory .. 'events/DisablePlacementPriceStateEvent.lua')

local placeAnywhereError = {
    displayNumSeconds = 3,
    timeExpire = false,
    errorCode = 0,
    errorMessage = '',
}

-- We (client) got an error event from server
PlaceAnywhere.onErrorEvent = function(code, message)
    placeAnywhereError.timeExpire = g_currentMission.time + 3 * 1000
    placeAnywhereError.errorCode = code
    placeAnywhereError.errorMessage = message
end

-- Broadcast state event to all clients
PlaceAnywhere.broadcastState = function()
    local event = PlaceAnywhereStateEvent:new(PlaceAnywhere.enablePlaceAnywhere, PlaceAnywhere.overrideAreaOwnerCheck, PlaceAnywhere.dismissTerrainDeformation, PlaceAnywhere.disablePlacementPrice)
    g_server:broadcastEvent(event, true)
end

-- Send state data to specific client after request (PlaceAnywhereStateRequestEvent)
---@param connection Connection
PlaceAnywhere.sendStateEvent = function(connection)
    local event = PlaceAnywhereStateEvent:new(PlaceAnywhere.enablePlaceAnywhere, PlaceAnywhere.overrideAreaOwnerCheck, PlaceAnywhere.dismissTerrainDeformation, PlaceAnywhere.disablePlacementPrice)
    connection:sendEvent(event)
end

-- Send error event to specific client
---@param connection Connection
---@param code number
---@param message string
PlaceAnywhere.sendErrorEvent = function(connection, code, message)
    local event = PlaceAnywhereErrorEvent:new(code, message)
    connection:sendEvent(event)
end

function PlaceAnywhere:loadMap()
    --g_currentMission.addChatMessage = Utils.overwrittenFunction(g_currentMission.addChatMessage, PlaceAnywhere.addChatMessage)

    -- Original code from PlaceAnywhere to allow overlapping placeable objects
    PlacementScreenController.onTerrainValidationFinished = Utils.overwrittenFunction(PlacementScreenController.onTerrainValidationFinished, PlaceAnywhere.onTerrainValidationFinished)
    PlacementUtil.hasObjectOverlap = Utils.overwrittenFunction(PlacementUtil.hasObjectOverlap, PlaceAnywhere.hasObjectOverlap)
    PlacementUtil.hasOverlapWithPoint = Utils.overwrittenFunction(PlacementUtil.hasOverlapWithPoint, PlaceAnywhere.hasOverlapWithPoint)
    PlacementUtil.isInsidePlacementPlaces = Utils.overwrittenFunction(PlacementUtil.isInsidePlacementPlaces, PlaceAnywhere.isInsidePlacementPlaces)
    PlacementUtil.isInsideRestrictedZone = Utils.overwrittenFunction(PlacementUtil.isInsideRestrictedZone, PlaceAnywhere.isInsideRestrictedZone)
    TerrainDeformation.setBlockedAreaMap = Utils.overwrittenFunction(TerrainDeformation.setBlockedAreaMap, PlaceAnywhere.setBlockedAreaMap)
    TerrainDeformation.setDynamicObjectCollisionMask = Utils.overwrittenFunction(TerrainDeformation.setDynamicObjectCollisionMask, PlaceAnywhere.setDynamicObjectCollisionMask)
    -- End original code

    -- Override area owner check for placeables
    PlacementScreenController.isPlacementValid = Utils.overwrittenFunction(PlacementScreenController.isPlacementValid, PlaceAnywhere.isPlacementValid)

    -- Override area owner check for landscaping
    Landscaping.isModificationAreaOnOwnedLand = Utils.overwrittenFunction(Landscaping.isModificationAreaOnOwnedLand, PlaceAnywhere.isModificationAreaOnOwnedLand);

    -- Override terrain displacement when placing objects (no terraforming)
    Placeable.addPlaceableLevelingArea = Utils.overwrittenFunction(Placeable.addPlaceableLevelingArea, PlaceAnywhere.addPlaceableLevelingArea)
    Placeable.addPlaceableRampArea = Utils.overwrittenFunction(Placeable.addPlaceableRampArea, PlaceAnywhere.addPlaceableRampArea)

    if g_server == nil then
        -- Client (MP)
        -- We can't send any events right now (will give error with invalid event id)
        -- so we send the request event after onStartMission()
        g_currentMission.onStartMission = Utils.appendedFunction(g_currentMission.onStartMission, PlaceAnywhere.onStartMission)
    else
        -- Server (SP,MP,dedicated)
        -- Load settings if found
        pcall(PlaceAnywhere.loadFromXml)
        -- Append to onSaveComplete to save our own XML settings
        SavegameController.onSaveComplete = Utils.appendedFunction(SavegameController.onSaveComplete, PlaceAnywhere.onSaveComplete)
    end
end

-- Request state data from server
function PlaceAnywhere.onStartMission()
    g_client:getServerConnection():sendEvent(PlaceAnywhereStateRequestEvent:new())
end

-- The game has now saved savegame data, so let's save our own XML file
function PlaceAnywhere.onSaveComplete()
    pcall(PlaceAnywhere.saveToXml)
end

-- Get XML file location (inside current savegame folder)
---@return string
function PlaceAnywhere.getXmlFilePath()
    return g_currentMission.missionInfo.savegameDirectory .. '/placeanywhere.xml'
end

-- Load XML file state data (if it exists)
function PlaceAnywhere.loadFromXml()
    -- Load XML file only if we're on the server side (SP,MP,dedicated)
    if g_server ~= nil then
        local filePath = PlaceAnywhere.getXmlFilePath()
        if not fileExists(filePath) then
            return
        end
        local xmlFile = loadXMLFile('PlaceAnywhereStateXml', filePath)
        if xmlFile ~= nil and xmlFile ~= 0 then
            local xmlKeyPath = 'PlaceAnywhere.State'
            PlaceAnywhere.enablePlaceAnywhere = Utils.getNoNil(getXMLBool(xmlFile, xmlKeyPath .. '.enablePlaceAnywhere'), false)
            PlaceAnywhere.overrideAreaOwnerCheck = Utils.getNoNil(getXMLBool(xmlFile, xmlKeyPath .. '.overrideAreaOwnerCheck'), false)
            PlaceAnywhere.dismissTerrainDeformation = Utils.getNoNil(getXMLBool(xmlFile, xmlKeyPath .. '.dismissTerrainDeformation'), false)
            PlaceAnywhere.disablePlacementPrice = Utils.getNoNil(getXMLBool(xmlFile, xmlKeyPath .. '.disablePlacementPrice'), false)
        end
        delete(xmlFile)
    end
end

-- Save current state data to XML file
function PlaceAnywhere.saveToXml()
    -- Save XML file only if we're on the server side (SP,MP,dedicated)
    if g_server ~= nil then
        local xmlFile = createXMLFile('PlaceAnywhereStateXml', PlaceAnywhere.getXmlFilePath(), 'PlaceAnywhere')
        if xmlFile ~= nil and xmlFile ~= 0 then
            local xmlKeyPath = 'PlaceAnywhere.State'
            setXMLBool(xmlFile, xmlKeyPath .. '.enablePlaceAnywhere', PlaceAnywhere.enablePlaceAnywhere)
            setXMLBool(xmlFile, xmlKeyPath .. '.overrideAreaOwnerCheck', PlaceAnywhere.overrideAreaOwnerCheck)
            setXMLBool(xmlFile, xmlKeyPath .. '.dismissTerrainDeformation', PlaceAnywhere.dismissTerrainDeformation)
            setXMLBool(xmlFile, xmlKeyPath .. '.disablePlacementPrice', PlaceAnywhere.disablePlacementPrice)
            saveXMLFile(xmlFile)
        else
            print('Creating save state file failed .. : ' .. tostring(PlaceAnywhere.getXmlFilePath()))
        end
    end
end

-- Check if player has farm permission
---@param userId number
---@param permissionName string
---@return boolean
function playerHasPermission(userId, permissionName)
    local playerFarm = g_farmManager:getFarmByUserId(userId)
    if playerFarm ~= nil then
        local permissions = playerFarm:getUserPermissions(userId)
        if permissions ~= nil and permissions[permissionName] ~= nil then
            return true
        end
    end
    return false
end

function PlaceAnywhere:addPlaceableLevelingArea(superFunc, ...)
    if PlaceAnywhere.enablePlaceAnywhere and PlaceAnywhere.dismissTerrainDeformation then
        return true
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:addPlaceableRampArea(superFunc, ...)
    if PlaceAnywhere.enablePlaceAnywhere and PlaceAnywhere.dismissTerrainDeformation then
        return true
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:isPlacementValid(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere and PlaceAnywhere.overrideAreaOwnerCheck then
        return true
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:isModificationAreaOnOwnedLand(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere and PlaceAnywhere.overrideAreaOwnerCheck then
        return true
    end
    return superFunc(self,...)
end

function PlaceAnywhere:setBlockedAreaMap(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return true
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:hasObjectOverlap(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return false
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:isInsidePlacementPlaces(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return false
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:isInsideRestrictedZone(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return false
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:hasOverlapWithPoint(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return false
    end
    return superFunc(self, ...)
end

function PlaceAnywhere:setOutsideAreaConstraints(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return superFunc(self, 0, 0, 0);
    end
    return superFunc(self, ...);
end

function PlaceAnywhere:setDynamicObjectCollisionMask(superFunc, ...)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return superFunc(self, 0);
    end
    return superFunc(self, ...);
end

function PlaceAnywhere:onTerrainValidationFinished(superFunc, p1, p2, p3)
    if g_currentMission.placementController.camera.isActive and PlaceAnywhere.enablePlaceAnywhere then
        return superFunc(self, 0, p2, p3);
    end
    return superFunc(self, p1, p2, p3);
end

---@param state boolean
function PlaceAnywhere:setIsEnabled(state)
    g_client:getServerConnection():sendEvent(PlaceAnywhereEnableStateEvent:new(state))
end

---@param state boolean
function PlaceAnywhere:setDisablePlacementPriceEnabled(state)
    g_client:getServerConnection():sendEvent(DisablePlacementPriceStateEvent:new(state))
end

---@param state boolean
function PlaceAnywhere:setIsDismissTerrainDeformationEnabled(state)
    g_client:getServerConnection():sendEvent(DismissTerrainDeformationStateEvent:new(state))
end

---@param state boolean
function PlaceAnywhere:setIsOverrideAreaOwnerCheckEnabled(state)
    g_client:getServerConnection():sendEvent(OverrideAreaOwnerCheckStateEvent:new(state))
end


----------------------------------------------------------------


---@param unicode
---@param sym
---@param modifier
---@param isDown
function PlaceAnywhere:keyEvent(unicode, sym, modifier, isDown)

    if not isDown then
        return
    end

    -- Easy way to check if we're in the placement screen or not
    if g_currentMission.placementController.camera.isActive ~= true then
        return
    end

    if sym == Input.KEY_h then
        self:setIsEnabled(not PlaceAnywhere.enablePlaceAnywhere)
    elseif sym == Input.KEY_j then
        self:setIsDismissTerrainDeformationEnabled(not PlaceAnywhere.dismissTerrainDeformation)
    elseif sym == Input.KEY_k then
        self:setIsOverrideAreaOwnerCheckEnabled(not PlaceAnywhere.overrideAreaOwnerCheck)
    elseif sym == Input.KEY_l then
        self:setDisablePlacementPriceEnabled(not PlaceAnywhere.disablePlacementPrice)
    end
end


----------------------------------------------------------------


local defaultFontSize = 0.014
local defaultLineHeight = getTextHeight(defaultFontSize, '|')
local defaultTextColor = {1, 1, 1, 1}
local defaultTextShadowColor = {0, 0, 0, .5}

function renderTextWithShadow(x, y, text, textColor, shadowColor, align)
    if align ~= nil then
        setTextAlignment(align)
    else
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    setTextColor(unpack(shadowColor or defaultTextShadowColor))
    renderText(x + defaultLineHeight * 0.025, y - defaultLineHeight * 0.025, defaultFontSize, text)
    setTextColor(unpack(textColor or defaultTextColor))
    renderText(x, y, defaultFontSize, text)
end


function PlaceAnywhere:draw()
    if placeAnywhereError.timeExpire and placeAnywhereError.timeExpire > g_currentMission.time then
        renderTextWithShadow(.5, .5, ('Error: %s'):format(tostring(placeAnywhereError.errorMessage)), {1, 0, 0, 1}, nil, RenderText.ALIGN_CENTER)
    end

    if g_currentMission.placementController.camera.isActive ~= true then
        return
    end
    if not PlaceAnywhere.enablePlaceAnywhere then
        renderTextWithShadow(.2, .90, ('enabledPlaceAnywhere = %s'):format(tostring(PlaceAnywhere.enablePlaceAnywhere)))
        renderTextWithShadow(.2, .88, 'Press H to toggle')
        return
    end

    renderTextWithShadow(.2, .90, ('enabledPlaceAnywhere = %s'):format(tostring(PlaceAnywhere.enablePlaceAnywhere)))
    renderTextWithShadow(.2, .88, ('dismissTerrainDeformation = %s'):format(tostring(PlaceAnywhere.dismissTerrainDeformation)))
    renderTextWithShadow(.2, .86, ('overrideAreaOwnerCheck = %s'):format(tostring(PlaceAnywhere.overrideAreaOwnerCheck)))
    renderTextWithShadow(.2, .84, ('disablePlacementPrice = %s'):format(tostring(PlaceAnywhere.disablePlacementPrice)))
end


----------------------------------------------------------------


addModEventListener(PlaceAnywhere);