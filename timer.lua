local addonName, addon = ...
local L, MyRegion
local TotalTime = 43200 -- Overall time 12 hours (6 special, 6 Standard just guessing! 6 Special + ??? standard)
local EventDuration = 600 -- Actual tracked event run time 4 minutes???
local RegionTimes = {
    [1] = {
        standard = { -- session A 6 hours
            starttime = 1709615040,
            eventinterval = 3600, -- runs every 1 hour
            enable = true,
            datablock = {}
        },
        special = { -- session B 6 hours
            starttime = 1709629200,
            eventinterval = 7200, -- but runs every 2 hours
            sessionduration = 18000, -- calculates 6 hours window where eventinterval is increased to 2 hours)
        },
    },
}
 
--[[ TEST TIMES ONLY: over 12 minutes instead of 12 hours ]]--
-- NOT EXACLTLY ACCURATE!!!!!
--[[
TotalTime = 720 -- 12 mins (6 special, 6 standard)
EventDuration = 20 -- event lasts 20 seconds instead of 4 minutes
 
RegionTimes[1].standard.eventinterval = 60 -- i minute instead of 1 hoiur
 
-- Special timming starts 4 intervals - 1 event time after standard start time (probably not completely accurate but just testing)
RegionTimes[1].special.starttime = RegionTimes[1].standard.starttime + ((RegionTimes[1].standard.eventinterval * 4) - EventDuration) -- + 4 mins - 1 event
RegionTimes[1].special.eventinterval = 120 -- Every 2 mins
RegionTimes[1].special.sessionduration = 360 -- Special time lasts 6 minutes (50% of TotalTime ?)
]]--
--[[ END TEST TIMES ]]--
 
local Localizations = {
    enUS = {
        Waiting = "|c1C7BCEFFTrial of the Elements:%s\nbefore the start: %s%s|r",
        Running = "|cFF35BE21Trial of the Elements:%s\n%s%s until completion|r",
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
    -- Check to see if we're in the special event time
    local isSpecial = ""
    local inEvent = CalcTime(MyRegion.special.starttime, serverTime, MyRegion.special.sessionduration, TotalTime) -- Are we in the 6 hour window?
    if inEvent then -- if so then calulate 2 hour intervals
        isSpecial = "|cffffff00*|r"
        inEvent, timeToRun = CalcTime(MyRegion.special.starttime, serverTime, EventDuration, MyRegion.special.eventinterval)
    else --  calulate 1 hour intervals (return to normal programming)
        inEvent, timeToRun = CalcTime(MyRegion.standard.starttime, serverTime, EventDuration, MyRegion.standard.eventinterval)
    end
    local hideSeconds = timeToRun >= 120
    local msg = L.Waiting
    local msgColor = "|cffffffff"
    if inEvent then
        msg = L.Running
    else
        if defaults.useColor and timeToRun <= defaults.alert2 then
            msgColor = defaults.alert2Color
        elseif timeToRun <= defaults.alert1 then
            if defaults.useSound and not self.Alerted then
                self.Alerted = true
                PlaySound(defaults.soundKit, "Master")
            end
            if defaults.useColor then
                msgColor = defaults.alert1Color
            end
        end
    end
    self.Text:SetText(format(msg, isSpecial, msgColor, SecondsToTime(timeToRun, hideSeconds)))
end
 
------------------------------------------------------------------------------------------------------ 
local Backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
}
 
local frame_x = 100     
local frame_y = -250    
local f = CreateFrame("Button", "ZAMTimer777", UIParent, "BackdropTemplate")
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
    self:SetScript("OnUpdate", function(self, elapsed)
    self.Elapsed = self.Elapsed - elapsed
    if self.Elapsed > 0 then -- Only check once per second
        return
    end
    self.Elapsed = 1 -- reset the timeout (we've counted down 1 second)
    printTime(self)
    end)
end)
