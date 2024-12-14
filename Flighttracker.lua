------Section 1--------


-- Initialize the addon
-- print("FlightTracker Addon Loaded")

local frame = CreateFrame("Frame")
local selectedDestination = nil

-- Default position values (center of the screen)
local defaultPosition = { "CENTER", UIParent, "CENTER", 0, 0 }

-- Ensure global scope
FlightTrackerGlobalDB = FlightTrackerGlobalDB or {}
-- print("GlobalDB Initialized")

-- Function to save the position of the flight tracker frame
function frame:SaveFramePosition()
    if FlightTrackerFrame and FlightTrackerFrame:IsShown() then
        local point, relativeTo, relativePoint, xOfs, yOfs = FlightTrackerFrame:GetPoint()
        FlightTrackerGlobalDB.position = { point, relativeTo, relativePoint, xOfs, yOfs }
        -- print("Frame position saved.")  -- Debugging message
    else
        -- print("Frame not visible. Position not saved.")  -- Debugging message
    end
end

-- Function to restore the position of the flight tracker frame
function frame:RestoreFramePosition()
    if FlightTrackerGlobalDB.position then
        local point, relativeTo, relativePoint, xOfs, yOfs = unpack(FlightTrackerGlobalDB.position)
        FlightTrackerFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        -- print("Frame position restored.")  -- Debugging message
    else
        FlightTrackerFrame:SetPoint(unpack(defaultPosition))
        -- print("Frame position set to default.")  -- Debugging message
    end
end

-- Function to hide the progress bar
function frame:HideProgressBar()
    self:SetScript("OnUpdate", nil)
    local flightFrame = FlightTrackerFrame
    if flightFrame then
        flightFrame:Hide()
        -- print("Progress bar hidden.")  -- Debugging message
    end
end

-- Function to show the progress bar
function frame:ShowProgressBar()
    -- print("ShowProgressBar called.")  -- Debugging message
    local flightFrame = FlightTrackerFrame
    if flightFrame then
        -- print("FlightTrackerFrame found.")  -- Debugging message
        local statusBar = flightFrame.StatusBar
        if statusBar then
            -- print("StatusBar found. Showing flightFrame.")  -- Debugging message
            flightFrame:Show()
            statusBar:SetMinMaxValues(0, self.totalFlightTime or 1) -- Min value can be 1 if totalFlightTime is nil
            statusBar:SetValue(0)
            flightFrame.StatusBarText:SetText("Flight Time: 0:00 / " .. (self.totalFlightTime and self:FormatTime(self.totalFlightTime) or "..."))
            -- print("Progress bar shown. totalFlightTime: " .. tostring(self.totalFlightTime))  -- Debugging message
            self:SetScript("OnUpdate", function(self, elapsed)
                self:UpdateProgressBar(elapsed)
            end)
        else
            -- print("StatusBar not found.")  -- Debugging message
        end
    else
        -- print("FlightTrackerFrame not found.")  -- Debugging message
    end
end

-- Function to update the progress bar
function frame:UpdateProgressBar(elapsed)
    -- print("UpdateProgressBar called.")  -- Debugging message
    if self.startTime then
        local duration = GetTime() - self.startTime
        local roundedDuration = math.floor(duration) -- Round duration to nearest second
        local statusBar = FlightTrackerFrame.StatusBar

        -- Debugging the elapsed time
        -- print("Elapsed time: " .. tostring(roundedDuration) .. " seconds.")  -- Debugging message

        -- Format the elapsed time in mm:ss format
        local formattedElapsedTime = self:FormatTime(roundedDuration)
        local formattedTotalTime = self.totalFlightTime and self:FormatTime(self.totalFlightTime) or "... / ..."

        -- Set the status bar text
        if statusBar then
            statusBar:SetValue(roundedDuration)
            FlightTrackerFrame.StatusBarText:SetText(formattedElapsedTime .. " / " .. formattedTotalTime)
            -- print("Progress bar updated. Elapsed: " .. formattedElapsedTime .. " / " .. formattedTotalTime)  -- Debugging message
        else
            -- print("StatusBar not found.")  -- Debugging message
        end

        -- Check if the player has landed
        if not UnitOnTaxi("player") then
            -- print("Player has landed.")  -- Debugging message
            self:HideProgressBar()
            self:HideFlightPathTextFrame()
            self:SaveFlightTime()  -- Save the new flight time if it has increased or decreased
        end
    else
        -- print("No startTime found.")  -- Debugging message
    end
end

-- Function to save the flight time
function frame:SaveFlightTime()
    if not self.origin or not self.destination or not self.startTime then
        return
    end

    local duration = GetTime() - self.startTime
    if not FlightTrackerGlobalDB[self.origin] then
        FlightTrackerGlobalDB[self.origin] = {}
    end

    -- Save the flight time if it's longer than the existing one or if no time is recorded
    if not FlightTrackerGlobalDB[self.origin][self.destination] or duration > FlightTrackerGlobalDB[self.origin][self.destination] then
        FlightTrackerGlobalDB[self.origin][self.destination] = duration
        -- print("Flight time saved. Origin: " .. self.origin .. ", Destination: " .. self.destination .. ", Duration: " .. self:FormatTime(duration))  -- Debugging message
        -- print("Recorded new time for flight from " .. self.origin .. " to " .. self.destination) -- Debugging message for new time
    end

    self.startTime = nil  -- Reset the start time after saving
end

-- Function to format time in mm:ss format
function frame:FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%d:%02d", minutes, remainingSeconds)  -- Format as mm:ss
end






------Section 2---------


-- Function to update the progress bar
function frame:UpdateProgressBar(elapsed)
    -- print("UpdateProgressBar called.")  -- Debugging message
    if self.startTime then
        local duration = GetTime() - self.startTime
        local roundedDuration = math.floor(duration) -- Round duration to nearest second
        local statusBar = FlightTrackerFrame.StatusBar

        -- Debugging the elapsed time
        -- print("Elapsed time: " .. tostring(roundedDuration) .. " seconds.")  -- Debugging message

        -- Format the elapsed time in mm:ss format
        local formattedElapsedTime = self:FormatTime(roundedDuration)
        local formattedTotalTime = self.totalFlightTime and self:FormatTime(self.totalFlightTime) or "..."

        -- Set the status bar text
        if statusBar then
            statusBar:SetValue(roundedDuration)
            FlightTrackerFrame.StatusBarText:SetText(formattedElapsedTime .. " / " .. formattedTotalTime)
            -- print("Progress bar updated. Elapsed: " .. formattedElapsedTime .. " / " .. formattedTotalTime)  -- Debugging message
        else
            -- print("StatusBar not found.")  -- Debugging message
        end

        -- Check if the player has landed
        if not UnitOnTaxi("player") then
            -- print("Player has landed.")  -- Debugging message
            self:HideProgressBar()
            self:HideFlightPathTextFrame()
            self:SaveFlightTime()  -- Save the new flight time if it has increased or decreased
        end
    else
        -- print("No startTime found.")  -- Debugging message
    end
end





-----Section 3------




-- Function to create and show the flight tracker frame
function frame:CreateAndShowFlightTrackerFrame()
    if FlightTrackerFrame then
        FlightTrackerFrame:Hide()
        FlightTrackerFrame:SetParent(nil)
        FlightTrackerFrame = nil
        -- print("Existing FlightTrackerFrame hidden and removed.")  -- Debugging message
    end

    -- Create main frame
    local flightFrame = CreateFrame("Frame", "FlightTrackerFrame", UIParent)
    flightFrame:SetSize(200, 30)
    flightFrame:SetPoint("CENTER")  -- Default position if no saved position
    -- print("Main frame created and positioned.")  -- Debugging message

    -- Create static background texture (grey)
    local statusBarBackground = flightFrame:CreateTexture(nil, "BACKGROUND")
    statusBarBackground:SetSize(180, 20)
    statusBarBackground:SetPoint("CENTER")
    statusBarBackground:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBarBackground:SetVertexColor(0.8, 0.8, 0.8, 1.0)  -- Light grey for the background
    -- print("Background texture created.")  -- Debugging message

    -- Create foreground StatusBar (blue)
    local statusBar = CreateFrame("StatusBar", "FlightTrackerFrameStatusBar", flightFrame)
    statusBar:SetSize(180, 20)
    statusBar:SetPoint("CENTER")
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    statusBar:SetStatusBarColor(0.0, 0.5, 1.0, 0.8)  -- Blue for the foreground
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(0)  -- Initially, no progress
    -- print("Status bar created.")  -- Debugging message

    -- Create FontString for status bar text
    local statusBarText = statusBar:CreateFontString("FlightTrackerStatusBarText", "OVERLAY", "GameFontNormalSmall")
    statusBarText:SetPoint("CENTER")
    statusBarText:SetText("Flight Time")
    -- print("Status bar text created.")  -- Debugging message

    -- Store references
    flightFrame.StatusBar = statusBar
    flightFrame.StatusBarText = statusBarText

    -- Tooltip for the frame
    flightFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Press Alt-Click to Move")
        GameTooltip:Show()
    end)
    flightFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Make the frame movable
    flightFrame:SetMovable(true)
    flightFrame:EnableMouse(true)
    flightFrame:RegisterForDrag("LeftButton")
    flightFrame:SetScript("OnDragStart", function(self)
        if IsAltKeyDown() then
            self:StartMoving()
            -- print("Frame moving started.")  -- Debugging message
        end
    end)
    flightFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        FlightTrackerGlobalDB.position = { point, "UIParent", relativePoint, xOfs, yOfs }
        -- print("Frame position saved.")  -- Debugging message
    end)

    flightFrame:Show()
    -- print("Flight tracker frame shown.")  -- Debugging message
end





----Section 4----


-- Create main frame for event handling
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TAXIMAP_OPENED")
frame:RegisterEvent("TAXIMAP_CLOSED")

frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    --print("Event triggered: " .. event)  -- Debugging message
    if event == "PLAYER_ENTERING_WORLD" then
        if not FlightTrackerGlobalDB then
            FlightTrackerGlobalDB = {}
        end
        self:CreateAndShowFlightTrackerFrame()
        self:CreateAndShowFlightPathTextFrame()
        self:HideProgressBar() -- Ensure the progress bar is hidden when the player enters the world
        -- Restore frame position if saved, otherwise set to default position
        self:RestoreFramePosition()
       -- print("PLAYER_ENTERING_WORLD event handled.")  -- Debugging message
    elseif event == "TAXIMAP_OPENED" then
        self.origin = self:GetCurrentTaxiNode() -- Get the current flight path node
        self:HookTaxiMap() -- Hook the TaxiMap to capture clicks
       -- print("TAXIMAP_OPENED event handled. Origin: " .. (self.origin or "unknown"))  -- Debugging message
    elseif event == "TAXIMAP_CLOSED" then
        self.startTime = GetTime()
        self.destination = selectedDestination -- Use the captured destination
        --print("TAXIMAP_CLOSED event handled. Destination: " .. (self.destination or "unknown"))  -- Debugging message

        if FlightTrackerGlobalDB[self.origin] and FlightTrackerGlobalDB[self.origin][self.destination] then
            self.totalFlightTime = FlightTrackerGlobalDB[self.origin][self.destination]
           -- print("Total flight time loaded: " .. self:FormatTime(self.totalFlightTime))  -- Debugging message
        else
            self.totalFlightTime = 1200 -- Set default max flight time to 20:00 (1200 seconds)
           -- print("No saved flight time found. Using default max flight time.")  -- Debugging message
        end
        self:ShowProgressBar()
        self:UpdateFlightPathText()
        self:ShowFlightPathTextFrame()
        --print("Flight tracker UI elements shown.")  -- Debugging message

        -- Check if player is on a taxi and start updating
        if UnitOnTaxi("player") then
           -- print("Player is on taxi. Starting progress update.")  -- Debugging message
            self:SetScript("OnUpdate", function(self, elapsed)
                self:UpdateProgressBar(elapsed)
            end)
        else
           -- print("Player not on taxi. Aborting progress update.")  -- Debugging message
        end
    end
end)

-- Function to check flight status
function frame:CheckFlightStatus()
    if not UnitOnTaxi("player") then
       -- print("Player has landed.")  -- Debugging message
        self:HideProgressBar()
        self:HideFlightPathTextFrame()
        self:SaveFlightTime() -- Save the flight time when the flight ends

        -- Unregister OnUpdate script
        self:SetScript("OnUpdate", nil)
    end
end

-- Function to get the current taxi node
function frame:GetCurrentTaxiNode()
    local numNodes = NumTaxiNodes()
    for i = 1, numNodes do
        if TaxiNodeGetType(i) == "CURRENT" then
            return TaxiNodeName(i)
        end
    end
    return nil
end

-- Function to hook taxi map
function frame:HookTaxiMap()
    for i = 1, NumTaxiNodes() do
        local button = _G["TaxiButton" .. i]
        if button then
            button:HookScript("OnClick", function()
                selectedDestination = TaxiNodeName(button:GetID())
               -- print("Destination selected: " .. (selectedDestination or "unknown"))  -- Debugging message
            end)
        end
    end
end

-- Function to create and show flight path text frame
function frame:CreateAndShowFlightPathTextFrame()
    if FlightPathTextFrame then
        FlightPathTextFrame:Hide()
        FlightPathTextFrame:SetParent(nil)
        FlightPathTextFrame = nil
    end

    -- Create text frame
    local textFrame = CreateFrame("Frame", "FlightPathTextFrame", UIParent)
    textFrame:SetSize(200, 30) -- Set size as needed
    textFrame:SetPoint("TOP", FlightTrackerFrame, "BOTTOM", 0, -5)

    -- Create FontString for flight path text
    local flightPathText = textFrame:CreateFontString("FlightPathText", "OVERLAY", "GameFontNormalSmall")
    flightPathText:SetPoint("BOTTOM", FlightTrackerFrame, "TOP", 0, 5) -- Position above the status bar
    flightPathText:SetText("Flight Path")
   -- print("Flight path text frame created.")  -- Debugging message

    -- Store references
    textFrame.Text = flightPathText

    textFrame:Hide()
end

function frame:ShowFlightPathTextFrame()
    if FlightPathTextFrame then
        FlightPathTextFrame:Show()
       -- print("Flight path text frame shown.")  -- Debugging message
    end
end

function frame:HideFlightPathTextFrame()
    if FlightPathTextFrame then
        FlightPathTextFrame:Hide()
       -- print("Flight path text frame hidden.")  -- Debugging message
    end
end

function frame:UpdateFlightPathText()
    local textFrame = FlightPathTextFrame
    local flightPathText = textFrame.Text
    if self.origin and self.destination then
        flightPathText:SetText(self.origin .. " ---> " .. self.destination)
       -- print("Flight path text updated: " .. self.origin .. " ---> " .. self.destination)  -- Debugging message
    else
        flightPathText:SetText("Flight Path: Unknown")
       -- print("Flight path text set to unknown.")  -- Debugging message
    end
end

-- Function to update the progress bar
function frame:UpdateProgressBar(elapsed)
   -- print("UpdateProgressBar called.")  -- Debugging message
    if self.startTime then
        local duration = GetTime() - self.startTime
        local roundedDuration = math.floor(duration) -- Round duration to nearest second
        local statusBar = FlightTrackerFrame.StatusBar

        -- Debugging the elapsed time
       -- print("Elapsed time: " .. tostring(roundedDuration) .. " seconds.")  -- Debugging message

        -- Format the elapsed time in mm:ss format
        local formattedElapsedTime = self:FormatTime(roundedDuration)
        local formattedTotalTime = self.totalFlightTime and self:FormatTime(self.totalFlightTime) or "..."

        -- Set the status bar text and range
        if statusBar then
            local maxFlightTime = self.totalFlightTime or 1200 -- Default max value to 20:00 (1200 seconds)
            statusBar:SetMinMaxValues(0, maxFlightTime)
            statusBar:SetValue(roundedDuration)
            FlightTrackerFrame.StatusBarText:SetText(formattedElapsedTime .. " / " .. (self.totalFlightTime and formattedTotalTime or "..."))
          --  print("Progress bar updated. Elapsed: " .. formattedElapsedTime .. " / " .. (self.totalFlightTime and formattedTotalTime or "..."))  -- Debugging message
        else
           -- print("StatusBar not found.")  -- Debugging message
        end

        -- Check if the player has landed
        if not UnitOnTaxi("player") then
          --  print("Player has landed.")  -- Debugging message
            self:HideProgressBar()
            self:HideFlightPathTextFrame()
            self:SaveFlightTime()  -- Save the new flight time if it has increased or decreased
        end
    else
       -- print("No startTime found.")  -- Debugging message
    end
end



----Section 5----


-- Function to dump the saved flight times
function frame:PrintSavedFlightTimes()
    if not FlightTrackerGlobalDB then
         print("No flight times recorded.")
        return
    end

     print("Saved Flight Times:")
    for origin, destinations in pairs(FlightTrackerGlobalDB) do
        if origin ~= "position" then  -- Skip the position key
            for destination, time in pairs(destinations) do
                 print(string.format("From %s to %s: %s", origin, destination, self:FormatTime(time)))
            end
        end
    end
end

-- Function to print the frame position
function frame:PrintFramePosition()
    if not FlightTrackerGlobalDB.position then
         print("No frame position saved.")
        return
    end

    local point, relativeTo, relativePoint, xOfs, yOfs = unpack(FlightTrackerGlobalDB.position)
     print(string.format("Frame Position: %s, %s, %s, %d, %d", point, relativeTo, relativePoint, xOfs, yOfs))
end

-- Function to show the status bar and flight path text frame for adjustment
function frame:ShowAdjustmentFrames()
    self:ShowProgressBar()
    self:UpdateFlightPathText()
    self:ShowFlightPathTextFrame()
     print("Adjustment frames shown. Move and adjust as needed, then save the position with /ftsavepos.")
end

-- Function to save the frame position
function frame:SaveAdjustmentPosition()
    self:SaveFramePosition()
    self:HideProgressBar()
    self:HideFlightPathTextFrame()
     print("Position saved and adjustment frames hidden.")
end

-- Register the /ftdump command
SLASH_FLIGHTTRACKER1 = "/ftdump"
SlashCmdList["FLIGHTTRACKER"] = function()
    frame:PrintSavedFlightTimes()
end

-- Register the /ftpos command
SLASH_FLIGHTTRACKERPOSITION1 = "/ftpos"
SlashCmdList["FLIGHTTRACKERPOSITION"] = function()
    frame:PrintFramePosition()
end

-- Register the /ftshowadjust command
SLASH_FLIGHTTRACKERSHOWADJUST1 = "/ftshowadjust"
SlashCmdList["FLIGHTTRACKERSHOWADJUST"] = function()
    frame:ShowAdjustmentFrames()
end

-- Register the /ftsavepos command
SLASH_FLIGHTTRACKERSAVEPOS1 = "/ftsavepos"
SlashCmdList["FLIGHTTRACKERSAVEPOS"] = function()
    frame:SaveAdjustmentPosition()
end




---end of addon---