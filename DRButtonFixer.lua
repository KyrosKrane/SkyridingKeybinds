-- Dragonriding Button Fixer
-- Written by KyrosKrane Sylvanblade (kyros@kyros.info)
-- Copyright (c) 2023 KyrosKrane Sylvanblade
-- Licensed under the MIT License, as per the included file.


-- Grab the WoW-defined addon folder name and storage table for our addon
local addonName, DRBF = ...


-- "If you get on a dragonriding mount, override the keybind to this spell; and when you dismount, remove the override."
-- "If you are a dracthyr and cast soar, override the keybind to this spell; and when you land, remove the override."

-- random non-UI frame to hold our keybindings and events
local DRBFFrame = CreateFrame("Frame")
local Events = {}

-- track our state
local BindingSet = "none" -- valid values are none, dragonriding, and dracthyr
local DracthyrGliding = false
local Timer


-- Settings to enable debug output
-- Note that this can be changed by a command line switch
local DRBFDebugMode = false

local function DebugPrint(...)
    if DRBFDebugMode then print("DRBF: ", ...) end
end


-- Toggles for the binding

local function RemoveBinding()
	DebugPrint("In RemoveBinding()")
    if "none" == BindingSet then return end

	ClearOverrideBindings(DRBFFrame)
	BindingSet = "none"
	DebugPrint("Binding removed")
end -- RemoveBinding()


local function SetBinding()
	DebugPrint("In SetBinding()")

	-- I'm not sure it's ever possible to get into a situation where you switch from dragonriding to Dracthyr gliding (or the other way) without interim events.
	-- But just in case, handle this swap scenario.
    if DracthyrGliding then
		if "dracthyr" == BindingSet then
			return
		elseif "dragonriding" == BindingSet then
			RemoveBinding()
		end
    else
        if "dragonriding" == BindingSet then
            return
		elseif "dracthyr" == BindingSet then
			RemoveBinding()
        end
	end

	-- Set the right bindings
	if DracthyrGliding then
		SetOverrideBinding(DRBFFrame, false, "BUTTON5", "SPELL Surge Forward(Racial)")
		SetOverrideBinding(DRBFFrame, false, "BUTTON4", "SPELL Skyward Ascent(Racial)")
		BindingSet = "dracthyr"
		DebugPrint("Dracthyr Binding set")
    else
	SetOverrideBinding(DRBFFrame, false, "BUTTON5", "SPELL Surge Forward")
	SetOverrideBinding(DRBFFrame, false, "BUTTON4", "SPELL Skyward Ascent")
	SetOverrideBinding(DRBFFrame, false, "BUTTON3", "SPELL Whirling Surge")
		BindingSet = "dragonriding"
		DebugPrint("Dragonriding Binding set")
end
end -- SetBinding()


-- This function holds the logic for when to toggle the bindings
local function CheckForStatusChange(IsCombatStarting)
    if InCombatLockdown() then return end

    local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
	--DebugPrint("In Check, Gliding is ", isGliding, ", BindingSet is ", BindingSet)
	if isGliding and "none" == BindingSet then
		SetBinding()
	elseif not isGliding and "none" ~= BindingSet then
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

-- This event fires when the game thinks we can glide, or when we stop being able to.
-- Note that the event is NOT reliable when state is true; it fires in many cases where the player can't actually glide.
function Events:PLAYER_CAN_GLIDE_CHANGED(NewGlideState)
    --DebugPrint("PLAYER_CAN_GLIDE_CHANGED is now ", NewGlideState)

    if DracthyrGliding and not NewGlideState then
		DracthyrGliding = false
		DebugPrint("Dracthyr Soar has ended")
	end
end -- Events:PLAYER_CAN_GLIDE_CHANGED()

-- This event fires when a spell is cast successfully.
-- We only care about one spell, so exit early if it's not our spell.
local DracthyrSoarSpellID = 369536
function Events:UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID)
    if "player" ~= unitTarget or DracthyrSoarSpellID ~= spellID then return end

    DracthyrGliding = true
	DebugPrint("Dracthyr Soar cast successfully")
end -- Events:UNIT_SPELLCAST_SUCCEEDED()





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

