-- Dragonriding Button Fixer
-- Written by KyrosKrane Sylvanblade (kyros@kyros.info)
-- Copyright (c) 2023 KyrosKrane Sylvanblade
-- Licensed under the MIT License, as per the included file.


-- Grab the WoW-defined addon folder name and storage table for our addon
local addonName, DRBF = ...


-- "If you get on a dragonriding mount, override the keybind to this spell; and when you dismount, remove the override."

-- random non-UI frame to hold our keybindings and events
local DRBFFrame = CreateFrame("Frame")
local Events = {}

-- track our state
local BindingSet = false
local Timer


-- Settings to enable debug output
-- Note that this can be changed
local DRBFDebugMode = false

local function DebugPrint(...)
    if DRBFDebugMode then print(...) end
end

-- Toggles for the binding

local function SetBinding()
	DebugPrint("In SetBinding()")
	if BindingSet then return end
	SetOverrideBinding(DRBFFrame, false, "BUTTON5", "SPELL Surge Forward")
	SetOverrideBinding(DRBFFrame, false, "BUTTON3", "SPELL Whirling Surge")
    BindingSet = true
	DebugPrint("Binding set")
end

local function RemoveBinding()
	DebugPrint("In RemoveBinding()")
	if not BindingSet then return end
	ClearOverrideBindings(DRBFFrame)
	BindingSet = false
	DebugPrint("Binding removed")
end


-- This function holds the logic for when to toggle the bindings
local function CheckForStatusChange(IsCombatStarting)
    if InCombatLockdown() then return end

    local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
	--DebugPrint("In Check, Gliding is ", isGliding, ", BindingSet is ", BindingSet)
	if isGliding and not BindingSet then
		SetBinding()
	elseif not isGliding and BindingSet then
		RemoveBinding()
	end
end

-- Functions to start and end the timer

local function StartTimer()
	DebugPrint("In StartTimer()")
	if Timer then return end
    Timer = C_Timer.NewTicker(0, function() CheckForStatusChange() end)
	DebugPrint("Timer started")
end

local function EndTimer()
	DebugPrint("In EndTimer()")
	if not Timer then return end
	Timer:Cancel()
    Timer = nil
	DebugPrint("Timer cancelled")
end

-- Capture the events we care about

-- Disable during combat to prevent lua errors.
function Events:PLAYER_REGEN_DISABLED()
	CheckForStatusChange(true)
	EndTimer()
end -- Events:PLAYER_REGEN_DISABLED()

-- Restore module settings after combat ends.
function Events:PLAYER_REGEN_ENABLED()
	StartTimer()
end -- Events:PLAYER_REGEN_ENABLED()

-- -- This event fires when we mount or dismount.
-- function Events:PLAYER_MOUNT_DISPLAY_CHANGED()
-- 	CheckForStatusChange()
-- end -- Events:PLAYER_MOUNT_DISPLAY_CHANGED()


-- Create the event handler function.
DRBFFrame:SetScript("OnEvent", function(self, event, ...)
	Events[event](self, ...) -- call one of the functions defined by the modules or above
end)

-- Register all events for which handlers have been defined
for k, v in pairs(Events) do
	DRBFFrame:RegisterEvent(k)
end

-- Initialize at load time
DebugPrint("DRBF loaded")
if not InCombatLockdown() then
	StartTimer()
end

-- register a slash command to toggle debug mode
SLASH_DRBFDEBUG1 = "/drbfdebug"
SlashCmdList.DRBFDEBUG = function(...)
	DRBFDebugMode = not DRBFDebugMode
end

