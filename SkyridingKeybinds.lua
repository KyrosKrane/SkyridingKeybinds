-- Skyriding Keybinds
-- Written by KyrosKrane Sylvanblade (kyros@kyros.info)
-- Copyright (c) 2023-2025 KyrosKrane Sylvanblade
-- Licensed under the MIT License, as per the included file.

-- Massively adapted from the implementation in the addon Inomena by p3lim (Adrian L Lange <addons@p3lim.net>)
-- https://github.com/p3lim-wow/Inomena/blob/master/modules/binding/skyriding.lua
-- and from his proposed simplifications on Discord chats


-- Grab the WoW-defined addon folder name and storage table for our addon
local addonName, SRKB = ...


-- Settings to enable debug output
local SRKBDebugMode = false

local function DebugPrint(...)
	if SRKBDebugMode then print("SRKB: ", ...) end
end


-- Initialize at load time
DebugPrint("loading")


-- These are the keybinds and spell IDs they should cast.
local ABILITIES = {
	{key = 'BUTTON4', spellID = 372610}, -- Skyward Ascent
	{key = 'BUTTON5', spellID = 372608}, -- Surge Forward
	{key = 'BUTTON3', spellID = 361584}, -- Whirling Surge
	-- {key = 'E', spellID = 425782}, -- Second Wind
	-- {key = 'T', spellID = 403092}, -- Aerial Halt
}
-- Note that the game intelligently handles Dracthyr Soar abilities, as well as the choice node between Whirling Surge and Lightning Rush. Essentially, it's all mapped automatically by the game. The spell IDs above are sufficient.


-- The state handler takes the result of the macro conditionals set during registration and either binds or unbinds the key to the action.
local STATE_HANDLER = [[
	if newstate == 'mounted' then
		self:SetBindingClick(true, self:GetAttribute('key'), self)
	elseif newstate == 'reset' then
		self:ClearBindings()
	end
]]


-- Create a button and keybinding combo for each ability.
for _, ability in next, ABILITIES do
	DebugPrint("Creating button for spellID " .. ability.spellID .. " bound to " .. ability.key)
	local button = CreateFrame('Button', addonName .. 'MountAbilityButton' .. ability.key, nil, 'SecureActionButtonTemplate, SecureHandlerStateTemplate')
	button:SetAttribute('type', 'spell')
	button:SetAttribute('spell', ability.spellID)
	button:SetAttribute('key', ability.key)
	button:SetAttribute('_onstate-skyriding', STATE_HANDLER)
	RegisterAttributeDriver(button, 'state-skyriding', '[bonusbar:5,flying] mounted; reset')
end


DebugPrint("Button keybinding complete")

