local addonName, addon = ...
local L, MyRegion
local RegionTimes = {
    [1] = {
        startTime = 1679572800,
        totalDuration = 14400, -- complete session time 4 hours repeating
        sub_sessionDuration = 3600, -- 1 hour
        waitTime = 3300, -- 55 minutes
        eventtime = 300, -- 5 minutes implied but..
        [1] = { -- sub-sessions
            name = "A",
        },
        [2] = {
            name = "B",
        },
        [3] = {
            name = "C",
        },
        [4] = {
            name = "D",
        },
    },
}
 
--[[ TEST TIMES ONLY: over 4 minutes instead of 4 hours ]]--
 
--[[
RegionTimes[1].totalDuration = 240 -- 4 minutes
RegionTimes[1].sub_sessionDuration = 60 -- 1 minute
RegionTimes[1].waitTime = 55 -- seconds
RegionTimes[1].eventtime = 5 -- seconds
]]--
 
--[[ END TEST TIMES ]]--
 
local Localizations = {
    enUS = {
        Waiting = "%s before event %s starts",
        Running = "Event: |cFF35BE21%s|r\n%s remaining",
    },
}
 
local function OnUpdate(self, elapsed)
    self.Elapsed = self.Elapsed - elapsed
    if self.Elapsed > 0 then -- Only check once per second
        return
    end
    self.Elapsed = 1 -- reset the timeout (we've counted down 1 second)
    local serverTime = GetServerTime()
    local remainingTime = (MyRegion.startTime - serverTime) % MyRegion.totalDuration
    local base = math.ceil(remainingTime / MyRegion.sub_sessionDuration)
    local hourRemaining = MyRegion.sub_sessionDuration - ((base * MyRegion.sub_sessionDuration) - remainingTime)
    local id = 4 - (base - 1)
    if id == 5 then
        id = 1
    end
    local msg
    if hourRemaining > MyRegion.waitTime then
        msg = format(L.Running, MyRegion[id].name, SecondsToTime(hourRemaining - MyRegion.waitTime, false))
    else
        id = id == 4 and 1 or id + 1
        msg = format(L.Waiting, SecondsToTime(hourRemaining, false), MyRegion[id].name)
    end
    self.Text:SetText(msg)
    self:SetSize(self.Text:GetWidth() + 10, self.Text:GetHeight() + 10)
end
 
local Backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
}
 
local f = CreateFrame("Button", "ZAMTimer_4_Events", UIParent, "BackdropTemplate")
f:SetWidth(255)                                          
f:SetHeight(30)
f:SetPoint("CENTER")
f:SetBackdrop(Backdrop)
f:SetClampedToScreen(true)
f:EnableMouse(true)
f:SetMovable(true)
f:SetUserPlaced(true)
f:RegisterForDrag("LeftButton")
f:RegisterForClicks("AnyUp")
f.Text = f:CreateFontString(nil, "OVERLAY", "GameTooltipText")
f.Text:SetPoint("CENTER")
f.Elapsed = 0 -- Set starting timeout (0 second)
f:SetScript("OnDragStart",function(self) 
    self:StartMoving()
end)
f:SetScript("OnDragStop",function(self)  
    self:StopMovingOrSizing()
end)
 
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    local locale = GetLocale()
    L = Localizations[locale] or Localizations.enUS -- Default to enUS if locale doesn't exist in the table
    MyRegion = RegionTimes[GetCurrentRegion()] or RegionTimes[1] -- Default to region 1 (US) if it doesn't exist in the table
    f:SetScript("OnUpdate", OnUpdate)
end)
 
SLASH_ZAM4TIMER1 = "/z4" -- toggle hiding/showing the ZAMTimer_4_Events frame using just /z4
SlashCmdList.ZAM4TIMER = function(msg)
    ZAMTimer_4_Events.Elapsed = 0 -- set the "clock" to re-calculate when shown.
    ZAMTimer_4_Events:SetShown(not ZAMTimer_4_Events:IsShown()) -- hide/show the frame
end
