local addonName, addon = ...
local L, MyRegion
local RegionTimes = {
    [1] = {
        startTime = 1710482400, 
        totalDuration = 18000, -- complete session time 5 hours repeating
        A = { -- sub-session -- event runs 3 times
            duration = 7200, -- 2 hours 
            interval = 3600, -- runs every 2 hour
            eventtime = 300, -- 5 minutes run time
        },
        B = { -- sub-session -- just waiting.
            duration = 10500, -- 3 hours 55 minutes
        },
    },
}
 
--[[ TEST TIMES ONLY: over 6 minutes instead of 6 hours ]]--
 
--[[
RegionTimes[1].totalDuration = 360 -- 6 minutes
RegionTimes[1].A.duration = 124 -- 2 minutes 4 seconds
RegionTimes[1].A.interval = 60 -- 1 minute
RegionTimes[1].A.eventtime = 4 -- 4 seconds
 
RegionTimes[1].B.duration = 236 -- 3 minute 56 seconds
]] --
 
--[[ END TEST TIMES ]]--
 
local Localizations = {
    enUS = {
        Waiting = "|cFFDEB887Trial of the Elements:%s\nbefore the start: %s%s|r",
        Running = "|cFF35BE21Trial of the Elements:%s\n%s%s until completion|r",
    },
	ruRU = {
        Waiting = "|cFFDEB887Испытание Стихий:%s\nдо начала: %s%s|r",
        Running = "|cFF35BE21Испытание Стихий:%s\n%s%s до завершения|r",
    },
}
 
------------------------------------------------------------------------------------------------------ 
-- These might be converted to Saved Variables so each character can determine
-- wether or not to play a sound, the alert times and colors and sound to play.
-- If so then most of the code below will have to move into an event handler for 
-- the PLAYER_LOGIN or PLAYER_ENTERING_WORLD event.
local defaults = {
    useColor = true,
    useSound = true,
    alert1 = 600, -- Alarm 1 set to 10 minutes before event
    alert1Color = "|cffffff00", -- Yellow
    alert2 = 300, -- Alarm 2 set to 5 minutes before event
    alert2Color = "|cffff0000", -- Red
    soundKit = 32585, -- Alarm sound
}
 
------------------------------------------------------------------------------------------------------ 
local function CalcTime(starttime, servertime, duration, interval)
    local timeToEvent = (starttime - servertime) % interval
    local inEvent, timeToRun
    if timeToEvent > (interval - duration) then -- Is there between 1:15 and 1:30 to go? If so, we're in the event
        inEvent = true
        timeToRun = duration - (interval - timeToEvent)
    else                    -- Otherwise, set the timer to time to next event
        inEvent = false
        timeToRun = timeToEvent
    end
    return inEvent, timeToRun
end
 
local function printTime(self)
    local serverTime = GetServerTime()
    -- Calculate remaining time in current cycle
    local remainingTime = (MyRegion.startTime - serverTime) % MyRegion.totalDuration
    local longWait = ""
    local inEvent
    if remainingTime > RegionTimes[1].B.duration then -- in Session A time
    inEvent, remainingTime = CalcTime(MyRegion.startTime, serverTime, MyRegion.A.eventtime, MyRegion.A.interval)
    else -- in Session B time
    longWait = "|cffffff00*|r"
    end
    local hideSeconds = remainingTime >= 120
    local msg = L.Waiting
    local msgColor = "|cffffffff"
    if inEvent then
        msg = L.Running
    else
        if defaults.useColor and remainingTime <= defaults.alert2 then
            msgColor = defaults.alert2Color
        elseif remainingTime <= defaults.alert1 then
            if defaults.useSound and not self.Alerted then
                self.Alerted = true
                PlaySound(defaults.soundKit, "Master")
            end
            if defaults.useColor then
                msgColor = defaults.alert1Color
            end
        end
    end
    self.Text:SetText(format(msg, longWait, msgColor, SecondsToTime(remainingTime, false)))
end
 
------------------------------------------------------------------------------------------------------ 
local Backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
}
 
local frame_x = 100     
local frame_y = -250    
local f = CreateFrame("Button", "ZAMTimer777", UIParent, "BackdropTemplate")
f:SetWidth(185)                                          
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
    self:SetScript("OnUpdate", function(self, elapsed)
    self.Elapsed = self.Elapsed - elapsed
    if self.Elapsed > 0 then -- Only check once per second
        return
    end
    self.Elapsed = 1 -- reset the timeout (we've counted down 1 second)
    printTime(self)
    end)
end)

SLASH_HUBB1 = "/hubb"
SlashCmdList["HUBB"] = function(msg)
    if strupper(strtrim(msg)) == "BTN" then -- toggle the shown state of the button if the type /hubb btn
        ZAMTimer777:SetShown(not ZAMTimer777:IsShown()) -- show the button
        return
    end
    updateData()
    updateList()
    ZAMTimer777:Show()
end
