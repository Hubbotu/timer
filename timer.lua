local addonName, addon = ...
local Backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
}
 
local frame_x = 100     
local frame_y = -250    
local f = CreateFrame("Button", "ZAMTimer777", UIParent, "BackdropTemplate")
f:SetWidth(255)                                          
f:SetHeight(30)
f:SetBackdrop(Backdrop)
f.text = f:CreateFontString(nil,"OVERLAY","GameTooltipText")
f.text:SetPoint("CENTER")
f:SetClampedToScreen(true)
f:SetPoint("CENTER",UIParent,"CENTER",frame_x,frame_y)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:RegisterForClicks("AnyUp")
f:Show()
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnDragStart",function(self) 
    self:StartMoving()
end)
f:SetScript("OnDragStop",function(self)  
    self:StopMovingOrSizing()
end)
-- first %s is replaced by the color. The second is replaced by the time. |r resets the color back to default
local Localizations = {
    enUS = {
        Waiting = "|cFFDEB887Trial of the Elements:\nbefore the start: %s%s|r",
        Running = "|cFF35BE21Trial of the Elements:\n%s%s until completion|r",
    },
	ruRU = {
        Waiting = "|cFFDEB887Испытание Стихий:\nдо начала: %s%s|r",
        Running = "|cFF35BE21Испытание Стихий:\n%s%s до завершения|r",
    },
}
 
local locale = GetLocale()
local L = Localizations[locale] or Localizations.enUS -- Default to enUS if locale doesn't exist in the table
 
------------------------------------------------------------------------------------------------------ 
-- These might be converted to Saved Variables so each character can determine
-- wether or not to play a sound, the alert times and colors and sound to play.
-- If so then most of the code below will have to move into an event handler for 
-- the PLAYER_LOGIN or PLAYER_ENTERING_WORLD event.
local useColor = true
local useSound = true
local alert1 = 600 -- Alarm 1 set to 10 minutes before event
local alert1Color = "|cffffff00" -- Yellow
local alert2 = 300 -- Alarm 2 set to 5 minutes before event
local alert2Color = "|cffff0000" -- Red
local soundKit = 32585 -- Alarm sound
------------------------------------------------------------------------------------------------------ 
 
local function printTime(timetotrun, inevent)
    local hideSeconds = timetotrun >= 120
    local msg = L.Waiting
    local msgColor = "|cffffffff"
    if inevent then
        msg = L.Running
    else
        if useColor and timetotrun <= alert2 then
            msgColor = alert2Color
        elseif timetotrun <= alert1 then
            if useSound and not ZAMTimer777.Alerted then
                ZAMTimer777.Alerted = true
                PlaySound(soundKit, "Master")
            end
            if useColor then
                msgColor = alert1Color
            end
        end
    end
    f.text:SetText(format(msg, msgColor, SecondsToTime(timetotrun, hideSeconds)))
end
 
regionEventStartTime = {
    [1] = { -- eu
        starttime = 1710075600,
        eventDuration = 480,
        eventIntervalInSeconds = 3600,
        enable = true,
        datablock = {}
    },
}
regionEventAdjustTime = { -- when the "adjustment" event occures
    [1] = {
        starttime = 1709615040, -- when the "adjustment" time starts
        eventDuration = 21600, -- How long "adjustment" lasts [6 hours]
        addIntervalInSeconds = 7200, -- Add seconds to event interval when in range, subtract when not
        addSomethingElse = 7200, -- Add something else when in adjust period like the event duration?
    },
}
 
local inEvent, timeToRun
local eventTime = regionEventStartTime[1].eventDuration -- Time the event runs in seconds(15 mins)
local waitTime = regionEventStartTime[1].eventIntervalInSeconds -- Time between events in seconds (90 mins)
local startTime = regionEventStartTime[1].starttime -- Start time from the table
local serverTime = GetServerTime()
local timeToEvent = (startTime - serverTime) % waitTime -- Remaining time before next event starts
if timeToEvent > (waitTime - eventTime) then -- Is there between 1:15 and 1:30 to go? If so, we're in the event
    inEvent = true
    timeToRun = eventTime - (waitTime - timeToEvent)
else                    -- Otherwise, set the ticker timer to time to next event
    inEvent = false
    timeToRun = timeToEvent
end
local ticker = C_Timer.NewTicker(1, function() 
    if timeToRun > 0 then
        timeToRun = timeToRun - 1
        printTime(timeToRun, inEvent)
        return
    end
    ZAMTimer777.Alerted = false
    if inEvent then -- The event just finished
        inEvent = false
        timeToRun = waitTime - eventTime -- Reset ticker timer to 90 minutes wait time minus 15 mins event time
    else  -- Waiting for the next event just expired
        inEvent = true
        timeToRun = eventTime -- And the event is running
    end
    printTime(timeToRun, inEvent)
end)
printTime(timeToRun, inEvent)