local addonName, addonTable = ...
 
local function UpdateTimer()
    if addonTable.timerEndTime then
        local timeLeft = addonTable.timerEndTime - GetTime()
        if timeLeft > 0 then
            local minutesLeft = math.floor(timeLeft / 60)
            local secondsLeft = math.floor(timeLeft % 60)
            if not addonTable.timerFrame then
                addonTable.timerFrame = CreateFrame("Frame", addonName.."TimerFrame", UIParent, "DialogBoxFrame")
                addonTable.timerFrame:SetSize(300, 300) -- Adjusted size
                addonTable.timerFrame:SetPoint("CENTER")
                addonTable.timerFrame:SetMovable(true)
                addonTable.timerFrame:EnableMouse(true)
                addonTable.timerFrame:RegisterForDrag("LeftButton")
                addonTable.timerFrame:SetScript("OnDragStart", addonTable.timerFrame.StartMoving)
                addonTable.timerFrame:SetScript("OnDragStop", addonTable.timerFrame.StopMovingOrSizing)
                addonTable.timerFrame:SetScript("OnHide", function(self) -- Added
                    self.UserHidden = true -- Added
                end) -- Added
                addonTable.timerFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                    edgeSize = 16,
                    insets = { left = 8, right = 6, top = 8, bottom = 8 },
                })
                addonTable.timerFrame:SetBackdropBorderColor(1, 1, 1)
                
                addonTable.timerFrame.textZone = addonTable.timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                addonTable.timerFrame.textZone:SetPoint("TOP", addonTable.timerFrame, "TOP", 0, -20)
                
                addonTable.timerFrame.textTimer = addonTable.timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                addonTable.timerFrame.textTimer:SetPoint("CENTER", addonTable.timerFrame, "CENTER", 0, 0)
                
                -- Create the delete button
                addonTable.timerFrame.deleteButton = CreateFrame("Button", nil, addonTable.timerFrame, "UIPanelCloseButton")
                addonTable.timerFrame.deleteButton:SetPoint("TOPRIGHT", addonTable.timerFrame, "TOPRIGHT")
                addonTable.timerFrame.deleteButton:SetScript("OnClick", function()
                    addonTable.timerFrame:Hide()
                end)
            end
            
            addonTable.timerFrame.textZone:SetText(addonTable.currentZone)
            if addonTable.spawning then
                addonTable.timerFrame.textTimer:SetText(string.format("Time ruin: %02d:%02d", minutesLeft, secondsLeft))
            else
                addonTable.timerFrame.textTimer:SetText(string.format("Time left: %02d:%02d", minutesLeft, secondsLeft))
            end
        else
            if addonTable.timerFrame then
                addonTable.timerFrame:Hide()
            end
        end
    end
end
 
local function UpdateLocation()
    local zone_rotation = {
        [0] = 84, -- Stormwind
        [1] = 2023, -- Ohn'ahran Plains
        [2] = 85, -- Orgrimmar
        [3] = 2024, -- The Azure Span
        [4] = 84, -- Stormwind
        [5] = 2025, -- Thaldraszus
        [6] = 85, -- Orgrimmar
        [7] = 2112, -- Valdrakken
        [8] = 84, -- Stormwind
        [9] = 2022, -- The Waking Shores
        [10] = 85, -- Orgrimmar
        [11] = 2023, -- Ohn'ahran Plains
        [12] = 84, -- Stormwind
        [13] = 2024, -- The Azure Span
        [14] = 85, -- Orgrimmar
        [15] = 2025, -- Thaldraszus
        [16] = 84, -- Stormwind
        [17] = 2112, -- Valdrakken
        [18] = 85, -- Orgrimmar
        [19] = 2022, -- The Waking Shores
    }
 
    local region_timers = {
        NA = 1685041200, -- NA
        US = 1685041200, -- NA
        KR = 1684962000, -- KR
        EU = 1685001600, -- EU
        TW = nil, -- TW (Add TW timestamp if available)
    }
 
    local region_start_timestamp = region_timers[GetCVar("portal"):upper()]
    if region_start_timestamp then
        local duration = 10 -- Adjusted duration
        local interval = 60 -- Adjusted interval
        local start_timestamp = GetServerTime() - region_start_timestamp
        local next_event = interval - start_timestamp % interval
        local spawning = interval - next_event < duration
        local remaining = duration - (interval - next_event)
 
        local offset = not spawning and interval or 0
        local rotation_index = math.floor((start_timestamp + offset) / interval % 20)
        local currentLocationID = zone_rotation[rotation_index]
        addonTable.currentZone = C_Map.GetMapInfo(currentLocationID).name
 
        addonTable.spawning = spawning
        if spawning then
            if addonTable.timerFrame and not addonTable.timerFrame.UserHidden then -- Added
                addonTable.timerFrame:Show() -- Moved
        end -- Added
            addonTable.timerEndTime = GetTime() + remaining
        else
            addonTable.timerEndTime = GetTime() + next_event
        end
    end
end
 
local function InitializeAddon()
    addonTable.states = {}
    addonTable.currentZone = ""
    addonTable.timerEndTime = nil
    addonTable.spawning = false
 
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event, ...) 
        if event == "PLAYER_ENTERING_WORLD" then
            UpdateLocation() -- Update location on entering world
        end
    end)
 
    frame:SetScript("OnUpdate", function() 
        UpdateTimer() -- Update timer continuously
        UpdateLocation() -- Update location continuously
    end)
end
 
InitializeAddon()
 
SLASH_ZAM4TIMER1 = "/zz" -- Added from here down
SlashCmdList.ZAM4TIMER = function(msg)
    if addonTable.timerFrame then
        addonTable.timerFrame.UserHidden = nil
        addonTable.timerFrame:Show()
    end
end