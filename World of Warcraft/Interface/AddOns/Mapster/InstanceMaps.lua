--[[
Copyright (c) 2009, Hendrik "Nevcairiel" Leppkes < h.leppkes@gmail.com >
All rights reserved.
]]

local Mapster = LibStub("AceAddon-3.0"):GetAddon("Mapster")
local L = LibStub("AceLocale-3.0"):GetLocale("Mapster")

local MODNAME = "InstanceMaps"
local Maps = Mapster:NewModule(MODNAME, "AceHook-3.0")

local LBZ = LibStub("LibBabble-Zone-3.0", true)
local BZ = LBZ and LBZ:GetLookupTable() or setmetatable({}, {__index = function(t,k) return k end})

-- Data mostly from http://www.wowwiki.com/API_SetMapByID
local data = {
	-- Northrend Instances
	iclassic = {
		["Ragefire Chasm"] = 680,
		["Zul'Farrak"] = 686,
		["The Temple of Atal'Hakkar"] = 687,
		["Blackfathom Deeps"] = 688,
		["The Stockade"] = 690,
		["Gnomeregan"] = 691,
		["Uldaman"] = 692,
		["Dire Maul"] = 699,
		["Blackrock Depths"] = 704,
		["Blackrock Spire"] = 721,
		["Wailing Caverns"] = 749,
		["Maraudon"] = 750,
		["The Deadmines"] = 756,
		["Razorfen Downs"] = 760,
		["Razorfen Kraul"] = 761,
		["Scarlet Monastery"] = 762,
		["Scholomance"] = 763,
		["Shadowfang Keep"] = 764,
		["Stratholme"] = 765,
	},
	ibc = {
		["The Shattered Halls"] = 710,
		["Auchenai Crypts"] = 722,
		["Sethekk Halls"] = 723,
		["Shadow Labyrinth"] = 724,
		["The Blood Furnace"] = 725,
		["The Underbog"] = 726,
		["The Steamvault"] = 727,
		["The Slave Pens"] = 728,
		["The Botanica"] = 729,
		["The Mechanar"] = 730,
		["The Arcatraz"] = 731,
		["Mana-Tombs"] = 732,
		["The Black Morass"] = 733,
		["Old Hillsbrad Foothills"] = 734,
		["Hellfire Ramparts"] = 797,
		["Magisters' Terrace"] = 798,
	},
	iwrath = {
		["The Nexus"] = 520,
		["The Culling of Stratholme"] = 521,
		["Ahn'kahet: The Old Kingdom"] = 522,
		["Utgarde Keep"] = 523,
		["Utgarde Pinnacle"] = 524,
		["Halls of Lightning"] = 525,
		["Halls of Stone"] = 526,
		["The Oculus"] = 528,
		["Gundrak"] = 530,
		["Azjol-Nerub"] = 533,
		["Drak'Tharon Keep"] = 534,
		["The Violet Hold"] = 536,
		["Trial of the Champion"] = 542,
		["The Forge of Souls"] = 601,
		["Pit of Saron"] = 602,
		["Halls of Reflection"] = 603,
	},

	-- Northrend Raids
	rclassic = {
		["Molten Core"] = 696,
		["Blackwing Lair"] = 755,
		["Ruins of Ahn'Qiraj"] = 717,
		["Ahn'Qiraj"] = 766,
		["Zul'Gurub"] = 697,
	},
	rbc = {
		["Hyjal Summit"] = 775,
		["Gruul's Lair"] = 776,
		["Magtheridon's Lair"] = 779,
		["Serpentshrine Cavern"] = 780,
		["The Eye"] = 782,
		["Sunwell Plateau"] = 789,
		["Black Temple"] = 796,
		["Karazhan"] = 799,
	},
	rwrath = {
		["The Eye of Eternity"] = 527,
		["Ulduar"] = 529,
		["The Obsidian Sanctum"] = 531,
		["Vault of Archavon"] = 532,
		["Naxxramas"] = 535,
		["Trial of the Crusader"] = 543,
		["Icecrown Citadel"] = 604,
		["The Ruby Sanctum"] = 609,
		["Onyxia's Lair"] = 718,
	},
	bgs = {
		["Alterac Valley"] = 401,
		["Warsong Gulch"] = 443,
		["Arathi Basin"] = 461,
		["Eye of the Storm"] = 482,
		["Strand of the Ancients"] = 512,
		["Isle of Conquest"] = 540,
	},
}

--[[
local db
local defaults = {
	profile = {
	}
}
]]

local options
local function getOptions()
	if not options then
		options = {
			type = "group",
			name = L["Instance Maps"],
			arg = MODNAME,
			get = optGetter,
			set = optSetter,
			args = {
				intro = {
					order = 1,
					type = "description",
					name = L["The Instance Maps module allows you to view the Instance and Battleground Maps provided by the game without being in the instance yourself."],
				},
				enabled = {
					order = 2,
					type = "toggle",
					name = L["Enable Instance Maps"],
					get = function() return Mapster:GetModuleEnabled(MODNAME) end,
					set = function(info, value) Mapster:SetModuleEnabled(MODNAME, value) end,
				},
			},
		}
	end

	return options
end

local zoomOverride

function Maps:OnInitialize()
	--[[
	self.db = Mapster.db:RegisterNamespace(MODNAME, defaults)
	db = self.db.profile
	]]

	self:SetEnabledState(Mapster:GetModuleEnabled(MODNAME))
	Mapster:RegisterModuleOptions(MODNAME, getOptions, L["Instance Maps"])

	self.zone_names = {}
	self.zone_data = {}

	for key, idata in pairs(data) do
		local names = {}
		local name_data = {}
		for name, zdata in pairs(idata) do
			tinsert(names, BZ[name])
			name_data[BZ[name]] = zdata
		end
		table.sort(names)
		self.zone_names[key] = names

		local zone_data = {}
		for k,v in pairs(names) do
			zone_data[k] = name_data[v]
		end
		self.zone_data[key] = zone_data
	end
	data = nil
end

function Maps:OnEnable()
	self:SecureHook("WorldMapContinentsDropDown_Update")
	self:SecureHook("WorldMapFrame_LoadContinents")

	self:SecureHook("WorldMapZoneDropDown_Update")
	self:RawHook("WorldMapZoneDropDown_Initialize", true)
	
	self:SecureHook("SetMapZoom")
	self:SecureHook("SetMapToCurrentZone", "SetMapZoom")
end

function Maps:OnDisable()
	self:UnhookAll()
	self.mapCont, self.mapContId, self.mapZone = nil, nil, nil
	WorldMapContinentsDropDown_Update()
	WorldMapZoneDropDown_Update()
end

function Maps:GetZoneData()
	return self.zone_data[self.mapCont][self.mapZone]
end

function Maps:WorldMapContinentsDropDown_Update()
	if self.mapCont then
		UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, self.mapContId)
	end
end

local function MapsterContinentButton_OnClick(frame)
	UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, frame:GetID())
	Maps.mapCont = frame.arg1
	Maps.mapContId = frame:GetID()
	zoomOverride = true
	SetMapZoom(-1)
	zoomOverride = nil
end

function Maps:WorldMapFrame_LoadContinents()
	local info = UIDropDownMenu_CreateInfo()
	
	info.text =  L["Classic Instances"]
	info.func = MapsterContinentButton_OnClick
	info.checked = nil
	info.arg1 = "iclassic"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Classic Raids"]
	info.func = MapsterContinentButton_OnClick
	info.checked = nil
	info.arg1 = "rclassic"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Burning Crusade Instances"]
	info.func = MapsterContinentButton_OnClick
	info.checked = nil
	info.arg1 = "ibc"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Burning Crusade Raids"]
	info.func = MapsterContinentButton_OnClick
	info.checked = nil
	info.arg1 = "rbc"
	UIDropDownMenu_AddButton(info)
	
	info.text =  L["Northrend Instances"]
	info.func = MapsterContinentButton_OnClick
	info.checked = nil
	info.arg1 = "iwrath"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Northrend Raids"]
	info.func = MapsterContinentButton_OnClick
	info.checked = nil
	info.arg1 = "rwrath"
	UIDropDownMenu_AddButton(info)

	info.text =  L["Battlegrounds"]
	info.func = MapsterContinentButton_OnClick
	info.checked = nil
	info.arg1 = "bgs"
	UIDropDownMenu_AddButton(info)
end

function Maps:WorldMapZoneDropDown_Update()
	if self.mapZone then
		UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, self.mapZone)
	end
end

local function MapsterZoneButton_OnClick(frame)
	UIDropDownMenu_SetSelectedID(WorldMapZoneDropDown, frame:GetID())
	Maps.mapZone = frame:GetID()
	SetMapByID(Maps:GetZoneData())
end

local function Mapster_LoadZones(...)
	local info = UIDropDownMenu_CreateInfo()
	for i=1, select("#", ...), 1 do
		info.text = select(i, ...)
		info.func = MapsterZoneButton_OnClick
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end
end

function Maps:WorldMapZoneDropDown_Initialize()
	if self.mapCont then
		Mapster_LoadZones(unpack(self.zone_names[self.mapCont]))
	else
		self.hooks.WorldMapZoneDropDown_Initialize()
	end
end

function Maps:SetMapZoom()
	if not zoomOverride then
		self.mapCont, self.mapContId, self.mapZone = nil, nil, nil
	end
end
