--[[
    Created by Slothpala 
--]]
local _, addonTable = ...
local addon = addonTable.RaidFrameSettings
local Debuffs = addon:NewModule("Debuffs")
Mixin(Debuffs, addonTable.hooks)
local CDT = addonTable.cooldownText
local Media = LibStub("LibSharedMedia-3.0")

--Debuffframe size
local SetSize = SetSize
local IsForbidden = IsForbidden
local ClearAllPoints = ClearAllPoints
local SetPoint = SetPoint
local SetTexture = SetTexture
local SetTexCoord = SetTexCoord
local SetTextureSliceMargins = SetTextureSliceMargins
local SetTextureSliceMode  = SetTextureSliceMode
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID

function Debuffs:OnEnable()
    local frameOpt = addon.db.profile.Debuffs.DebuffFramesDisplay
    --Timer
    local durationOpt = CopyTable(addon.db.profile.Debuffs.DurationDisplay) --copy is important so that we dont overwrite the db value when fetching the real values
    durationOpt.font = Media:Fetch("font", durationOpt.font)
    durationOpt.outlinemode = addon:ConvertDbNumberToOutlinemode(durationOpt.outlinemode)
    durationOpt.point = addon:ConvertDbNumberToPosition(durationOpt.point)
    durationOpt.relativePoint = addon:ConvertDbNumberToPosition(durationOpt.relativePoint)
    --Stack
    local stackOpt = CopyTable(addon.db.profile.Debuffs.StacksDisplay)
    stackOpt.font = Media:Fetch("font", stackOpt.font)
    stackOpt.outlinemode = addon:ConvertDbNumberToOutlinemode(stackOpt.outlinemode)
    stackOpt.point = addon:ConvertDbNumberToPosition(stackOpt.point)
    stackOpt.relativePoint = addon:ConvertDbNumberToPosition(stackOpt.relativePoint)
    --blacklist
    local blacklist = {}
    for spellId, value in pairs(addon.db.profile.Buffs.Blacklist) do
        blacklist[tonumber(spellId)] = true
    end
    --user placed 
    local userPlaced = {} --i will bring this at a later date for Debuffs including position and size
    --Debuffframe size
    local width  = frameOpt.width
    local height = frameOpt.height
    local boss_width  = width * frameOpt.increase
    local boss_height = height * frameOpt.increase
    local resizeDebuffFrame
    if frameOpt.cleanIcons then
        local left, right, top, bottom = 0.1, 0.9, 0.1, 0.9
        if height ~= width then
            if height < width then
                local delta = width - height
                local scale_factor = ((( 100 / width )  * delta) / 100) / 2
                top = top + scale_factor
                bottom = bottom - scale_factor
            else
                local delta = height - width 
                local scale_factor = ((( 100 / height )  * delta) / 100) / 2
                left = left + scale_factor
                right = right - scale_factor
            end
        end
        resizeDebuffFrame = function(debuffFrame)
            debuffFrame:SetSize(width, height)
            debuffFrame.icon:SetTexCoord(left,right,top,bottom)
            debuffFrame.border:SetTexture("Interface/AddOns/RaidFrameSettings/Textures/DebuffOverlay_clean_icons.tga")
            debuffFrame.border:SetTexCoord(0,1,0,1)
            debuffFrame.border:SetTextureSliceMargins(5.01, 26.09, 5.01, 26.09) 
            debuffFrame.border:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    else
        resizeDebuffFrame = function(debuffFrame)
            debuffFrame:SetSize(width, height)
        end
    end
    --Debuffframe position
    local point = addon:ConvertDbNumberToPosition(frameOpt.point)
    local relativePoint = addon:ConvertDbNumberToPosition(frameOpt.relativePoint)
    local followPoint, followRelativePoint = addon:GetAuraGrowthOrientationPoints(frameOpt.orientation)

    local function updateAnchors(frame)
        local anchorSet, prevFrame
        for i=1, #frame.debuffFrames do
            local debuffFrame = frame.debuffFrames[i]
            local aura = debuffFrame.auraInstanceID and frame.unit and GetAuraDataByAuraInstanceID(frame.unit, debuffFrame.auraInstanceID) or nil
            local hide = aura and blacklist[aura.spellId] or false
            local place = aura and userPlaced[aura.spellId] or false
            if not anchorSet and not hide and not place then 
                debuffFrame:ClearAllPoints()
                debuffFrame:SetPoint(point, frame, relativePoint, frameOpt.xOffset, frameOpt.yOffset)
                anchorSet = true
            else
                debuffFrame:ClearAllPoints()
                debuffFrame:SetPoint(followPoint, prevFrame, followRelativePoint, 0, 0)
            end
            if hide then
                debuffFrame:Hide()
            end
            if place and not hide then   
                debuffFrame:ClearAllPoints()
                debuffFrame:SetPoint(place.point, frame, place.relativePoint, place.xOffset, place.yOffset)
            end
            if not hide and not place then
                prevFrame = debuffFrame
            end
        end
    end

    local function onFrameSetup(frame)
        updateAnchors(frame)
        for i=1, #frame.debuffFrames do
            local debuffFrame = frame.debuffFrames[i]
            resizeDebuffFrame(debuffFrame)
            --Timer Settings
            local cooldown = debuffFrame.cooldown
            if frameOpt.timerText then
                local cooldownText = CDT:CreateOrGetCooldownFontString(cooldown)
                cooldownText:ClearAllPoints()
                cooldownText:SetPoint(durationOpt.point, debuffFrame, durationOpt.relativePoint, durationOpt.xOffsetFont, durationOpt.yOffsetFont)
                cooldownText:SetFont(durationOpt.font, durationOpt.fontSize, durationOpt.outlinemode)
                cooldownText:SetTextColor(durationOpt.fontColor.r, durationOpt.fontColor.g, durationOpt.fontColor.b)
                cooldownText:SetShadowColor(durationOpt.shadowColor.r, durationOpt.shadowColor.g, durationOpt.shadowColor.b,durationOpt.shadowColor.a)
                cooldownText:SetShadowOffset(durationOpt.xOffsetShadow, durationOpt.yOffsetShadow)
            end
            --Stack Settings
            local stackText = debuffFrame.count
            stackText:ClearAllPoints()
            stackText:SetPoint(stackOpt.point, debuffFrame, stackOpt.relativePoint, stackOpt.xOffsetFont, stackOpt.yOffsetFont)
            stackText:SetFont(stackOpt.font, stackOpt.fontSize, stackOpt.outlinemode)
            stackText:SetTextColor(stackOpt.fontColor.r, stackOpt.fontColor.g, stackOpt.fontColor.b)
            stackText:SetShadowColor(stackOpt.shadowColor.r, stackOpt.shadowColor.g, stackOpt.shadowColor.b,stackOpt.shadowColor.a)
            stackText:SetShadowOffset(stackOpt.xOffsetShadow, stackOpt.yOffsetShadow)
            --Swipe Settings
            cooldown:SetDrawSwipe(frameOpt.swipe)
            cooldown:SetReverse(frameOpt.inverse)
            cooldown:SetDrawEdge(frameOpt.edge)
        end
    end
    self:HookFuncFiltered("DefaultCompactUnitFrameSetup", onFrameSetup)

    local onSetDebuff = function(debuffFrame, aura)
        if debuffFrame:IsForbidden() then --not sure if this is still neede but when i created it at the start if dragonflight it was
            return 
        end
        local cooldown = debuffFrame.cooldown
        CDT:StartCooldownText(cooldown)
        cooldown:SetDrawEdge(frameOpt.edge)
        local parentFrame = debuffFrame:GetParent()
        if aura and aura.isBossAura then
            debuffFrame:SetSize(boss_width, boss_height)
        else
            debuffFrame:SetSize(width, height)
        end
        updateAnchors(parentFrame)
    end
    self:HookFunc("CompactUnitFrame_UtilSetDebuff", onSetDebuff)

    addon:IterateRoster(function(frame)
        onFrameSetup(frame)
        if frame.debuffFrames then
            for i=1, #frame.debuffFrames do
                local debuffFrame = frame.debuffFrames[i]
                if debuffFrame.auraInstanceID then
                    local aura = GetAuraDataByAuraInstanceID(frame.unit, debuffFrame.auraInstanceID)
                    if aura then
                        if blacklist[aura.spellId] then
                            debuffFrame:Hide()
                        else
                            debuffFrame:Show()
                        end
                    end
                end
            end
        end
    end)
end

--parts of this code are from FrameXML/CompactUnitFrame.lua
function Debuffs:OnDisable()
    self:DisableHooks()
    local restoreDebuffFrames = function(frame)
        local frameWidth = frame:GetWidth()
        local frameHeight = frame:GetHeight()
        local componentScale = min(frameWidth / NATIVE_UNIT_FRAME_HEIGHT, frameWidth / NATIVE_UNIT_FRAME_WIDTH)
        local buffSize = math.min(15, 11 * componentScale)
        for i=1,#frame.debuffFrames do  
            frame.debuffFrames[i]:SetSize(buffSize, buffSize)
        end
        local powerBarUsedHeight = frame.powerBar:IsShown() and frame.powerBar:GetHeight() or 0
        local debuffPos, debuffRelativePoint, debuffOffset = "BOTTOMLEFT", "BOTTOMRIGHT", CUF_AURA_BOTTOM_OFFSET + powerBarUsedHeight
        frame.debuffFrames[1]:ClearAllPoints()
        frame.debuffFrames[1]:SetPoint(debuffPos, frame, "BOTTOMLEFT", 3, debuffOffset)
        for i=1, #frame.debuffFrames do
            local debuffFrame = frame.debuffFrames[i]
            debuffFrame.border:SetTexture("Interface\\BUTTONS\\UI-Debuff-Overlays")
            debuffFrame.border:SetTexCoord(0.296875, 0, 0.296875, 0.515625, 0.5703125, 0, 0.5703125, 0.515625)
            debuffFrame.border:SetTextureSliceMargins(0,0,0,0)
            debuffFrame.icon:SetTexCoord(0,1,0,1)
            if ( i > 1 ) then
                debuffFrame:ClearAllPoints();
                debuffFrame:SetPoint(debuffPos, frame.debuffFrames[i - 1], debuffRelativePoint, 0, 0);
            end
            local cooldown = debuffFrame.cooldown
            cooldown:SetDrawSwipe(true)
            cooldown:SetReverse(false)
            cooldown:SetDrawEdge(false)
            CDT:DisableCooldownText(cooldown)
            --TODO
            --[[
                find global font for stacks and restore properly
            ]]
            local stackText = debuffFrame.count
            stackText:ClearAllPoints()
            stackText:SetPoint("BOTTOMRIGHT", debuffFrame, "BOTTOMRIGHT", 0, 0)
            stackText:SetFont("Fonts\\ARIALN.TTF", 12.000000953674, "OUTLINE")
            stackText:SetTextColor(1,1,1,1)
            stackText:SetShadowColor(0,0,0)
            stackText:SetShadowOffset(0,0)
        end
    end
    addon:IterateRoster(restoreDebuffFrames)
end
