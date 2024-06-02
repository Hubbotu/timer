local addonName, addonTable = ...

-- Create a frame to handle the addon
local frame = CreateFrame("Frame", addonName.."Frame", UIParent, "BackdropTemplate")

-- Set the backdrop for the frame
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

-- Position and size the frame
frame:SetPoint("CENTER")
frame:SetSize(300, 100)

-- Enable mouse dragging
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Create a font string for displaying information
local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
text:SetPoint("CENTER")
text:SetText("Hearthstone Timer")

-- Function to get the current region
local function DetermineRegion()
    local regions = {
        [1] = "US",  -- NA
        [2] = "KR",  -- Korea
        [3] = "EU",  -- Europe
        [4] = "TW",  -- Taiwan
        [5] = "CN",  -- China
    }
    return regions[GetCurrentRegion()]
end

-- Function to update the state
local function UpdateState()
    local region_timers = {
        ["US"] = 1698490800, -- NA
        ["KR"] = 1698447600, -- KR
        ["EU"] = 1698483600, -- EU
        ["TW"] = 1698483600, -- TW
        ["CN"] = nil,        -- CN (unavailable)
    }
    
    local region = DetermineRegion()
    local region_start_timestamp = region_timers[region]
    if region_start_timestamp then
        local duration = 300
        local interval = 1800
        local start_timestamp = GetServerTime() - region_start_timestamp
        local next_event = interval - start_timestamp % interval
        local spawning = interval - next_event < duration
        local remaining = duration - (interval - next_event)
        
        local state = {
            changed = true,
            show = true,
            progressType = "timed",
            autoHide = true,
            duration = spawning and duration or interval - duration,
            expirationTime = GetTime() + (spawning and remaining or next_event),
            spawning = spawning,
            name = "Hearthstone"
        }
        
        -- Update the frame text with the state information
        text:SetText(string.format("Next Event: %d seconds\nSpawning: %s", spawning and remaining or next_event, spawning and "Yes" or "No"))
    else
        -- If the region is not supported, display an error message
        text:SetText("Region not supported for Hearthstone events.")
    end
end

-- Set up a periodic timer to update the state every second
C_Timer.NewTicker(1, UpdateState)

-- Initialize by calling the update function once
UpdateState()
