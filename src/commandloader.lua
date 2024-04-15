---@class Param
---@field name string
---@field type? string
---@field default? string
---@field required boolean

---@class Vec2
---@field x number
---@field y number

---@class Menu
---@field name string
---@field description? string
---@field render boolean
---@field size Vec2
---@field type MenuType

---@class MenuChoice
---@field name string
---@field text string

---@class ChoiceMenu : Menu
---@field choices MenuChoice[]

---@class Command
---@field name string
---@field text string
---@field description? string
---@field enabled? boolean
---@field params? Param[]
---@field errors? string[]
---@field menus? Menu[]
---@field hasErrors boolean

---@class Note
---@field name string
---@field text string
---@field openOnStart boolean
---@field enabled boolean
---@field pinned boolean
---@field pos? Vec2
---@field size? Vec2
---@field FPS? number

---@class CommandSource
---@field name string
---@field author? string
---@field description? string
---@field enabled? boolean
---@field commands Command[]
---@field notes Note[]
---@field filepath string

local weapons = require "game.weapons"
local sandbox = require("lib.sandbox")

local util = require("src.util")
local isEmpty = util.isEmpty

local CommandLoader = {
	---@type CommandSource[]
	sources = {},
	dir = "commands",
}

local path = util.path_join(getWorkingDirectory(), CommandLoader.dir)
if not lfs.attributes(path) then
	lfs.mkdir(path)
end

---@enum MenuType
CommandLoader.menuTypes = {
	CHOICE = "choice",
}

CommandLoader.typeProcessor = {
	["player"] = function(param)
		local playerid = tonumber(param)

		local myid = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
		
		if not playerid then
			return false, "�������� ������ ID ������"
		end

		if playerid == myid then
			return myid
		end

		if not sampIsPlayerConnected(playerid) then
			return false, "����� �� ������"
		end

		return playerid
	end,
	["number"] = function(param)
		local num = tonumber(param)
		if not num then
			return false, "�������� ������ �����"
		end
		return num
	end,
	["bool"] = function(param)
		local bools = {
			["true"] = true,
			["false"] = false,
			["1"] = true,
			["0"] = false,
		}
		return bools[param] or false, "�������� ������ ����������� ��������, ����������� true/false ��� 1/0"
	end,
	["string"] = function(param)
		return param
	end,
	["vararg"] = function(param)
		return param
	end,
}

CommandLoader.rusTypes = {
	["player"] = u8"�����",
	["number"] = u8"�����",
	["bool"] = u8"���������� ��������",
	["string"] = u8"������",
	["vararg"] = u8"�������� ���������� �����",
}
local servers = {
	["80.66.82.162"] = { number = -1, name = "MOBILE I", runame = "������ I"},
	["80.66.82.148"] = { number = -2, name = "MOBILE II", runame = "������ II"},
	["80.66.82.136"] = { number = -3, name = "MOBILE III", runame = "������ III"},

    ["185.169.134.44"] = {number = 4, name = "Chandler", runame = "�������"},
    ["185.169.134.43"] = {number = 3, name = "Scottdale", runame = "���������"},
    ["185.169.134.45"] = {number = 5, name = "Brainburg", runame = "���������"},
    ["185.169.134.5"] = {number = 6, name = "Saint-Rose", runame = "����-����"},
    ["185.169.132.107"] = {number = 6, name = "Saint-Rose", runame = "����-����"},
    ["185.169.134.59"] = {number = 7, name = "Mesa", runame = "����"},
    ["185.169.134.61"] = {number = 8, name = "Red-Rock", runame = "���-���"},
    ["185.169.134.107"] = {number = 9, name = "Yuma", runame = "���"},
    ["185.169.134.109"] = {number = 10, name = "Surprise", runame = "��������"},
    ["185.169.134.166"] = {number = 11, name = "Prescott", runame = "��������"},
    ["185.169.134.171"] = {number = 12, name = "Glendale", runame = "��������"},
    ["185.169.134.172"] = {number = 13, name = "Kingman", runame = "�������"},
    ["185.169.134.173"] = {number = 14, name = "Winslow", runame = "�������"},
    ["185.169.134.174"] = {number = 15, name = "Payson", runame = "������"},
    ["80.66.82.191"] = {number = 16, name = "Gilbert", runame = "�������"},
    ["80.66.82.190"] = {number = 17, name = "Show Low", runame = "��� ���"},
    ["80.66.82.188"] = {number = 18, name = "Casa-Grande", runame = "����-������"},
    ["80.66.82.168"] = {number = 19, name = "Page", runame = "�����"},
    ["80.66.82.159"] = {number = 20, name = "Sun-City", runame = "���-����"},
    ["80.66.82.200"] = {number = 21, name = "Queen-Creek", runame = "����-����"},
    ["80.66.82.144"] = {number = 22, name = "Sedona", runame = "������"},
    ["80.66.82.132"] = {number = 23, name = "Holiday", runame = "�������"},
    ["80.66.82.128"] = {number = 24, name = "Wednesday", runame = "�������"},
    ["80.66.82.113"] = {number = 25, name = "Yava", runame = "���"},
    ["80.66.82.82"] = {number = 26, name = "Faraway", runame = "�������"},
    ["80.66.82.87"] = {number = 27, name = "Bumble Bee", runame = "����� ��"},
    ["80.66.82.54"] = {number = 28, name = "Christmas", runame = "��������"},
    ["185.169.134.3"] = {number = 1, name = "Phoenix", runame = "������"},
    ["185.169.132.105"] = {number = 1, name = "Phoenix", runame = "������"},
    ["185.169.134.4"] = {number = 2, name = "Tucson", runame = "������"},
    ["185.169.132.106"] = {number = 2, name = "Tucson", runame = "������"},
}

CommandLoader.env = {
	["time"] = function()
		return os.date("%H:%M:%S")
	end,
	["date"] = function()
		return os.date("%d.%m.%Y")
	end,
	["sexx"] = function()
		return cfg.general.sex == "�������" and "" or "�"
	end,
	["my_gun"] = function()
		return getCurrentCharWeapon(PLAYER_PED)
	end,
	["my_gun_weapon"] = function()
		return weapons.names[getCurrentCharWeapon(PLAYER_PED)]
	end,
	["my_lvl"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerScore(id)
	end,
	["my_armor"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerArmor(id)
	end,
	["my_hp"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerHealth(id)
	end,
	["my_id"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return id
	end,
	["my_nick"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerNickname(id)
	end,
	["my_name"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local nick = sampGetPlayerNickname(id)

		return nick:sub(1, nick:find("_") - 1)
	end,
	["my_surname"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local nick = sampGetPlayerNickname(id)

		return nick:sub(nick:find("_") + 1)
	end,
	["my_rpnick"] = function()
		return cfg.general.nickname
	end,
	["my_rpname"] = function()
		local nick = cfg.general.nickname

		return nick:sub(1, (nick:find(" ") or nick:find("_")) - 1)
	end,
	["my_rpsurname"] = function()
		local nick = cfg.general.nickname

		return nick:sub((nick:find(" ") or nick:find("_")) + 1)
	end,
	["my_car"] = function()
		if isCharInAnyCar(PLAYER_PED) then 
			local veh = storeCarCharIsInNoSave(PLAYER_PED)
			local idcar = getCarModel(veh)

			return util.arzcars[idcar] or "����������"
		end
		
		return nil
	end,
	
	["my_carcolor"] = function()
		if isCharInAnyCar(PLAYER_PED) then 
			local veh = storeCarCharIsInNoSave((PLAYER_PED))
			local color1, color2 = getCarColours(veh)
			
			return util.VehicleColoursRussianTable[color1]
		end
		
		return nil
	end,
	["my_fps"] = function()
		return imgui.GetIO().Framerate
	end,
	["random"] = function(n, n2)
		return math.random(n, n2)
	end,
	["city"] = function()
		local city = {
			[0] = "��������",
			[1] = "Los Santos",
			[2] = "San Fierro",
			[3] = "Las Venturas"
		}

		return city[getCityPlayerIsIn(PLAYER_HANDLE)]
	end,
	["street"] = function()
		return util.calculateZone(getCharCoordinates(PLAYER_PED))
	end,
	["nickid"] = function(id)
		return sampGetPlayerNickname(id)
	end,
	["rpnickid"] = function(id)
		return util.TranslateNick(sampGetPlayerNickname(id))
	end,
	["carid"] = function(id)
		local res, char = sampGetCharHandleBySampPlayerId(id)
		if res and isCharInAnyCar(char) then 
			local veh = storeCarCharIsInNoSave(char)
			local idcar = getCarModel(veh)

			return res and util.arzcars[idcar] or "����������"
		end
		
		return nil
	end,
	["carcolorid"] = function(id)
		local res, char = sampGetCharHandleBySampPlayerId(id)
		if res and isCharInAnyCar(char) then 
			local veh = storeCarCharIsInNoSave(char)
			local color1, color2 = getCarColours(veh)
			
			return util.VehicleColoursRussianTable[color1]
		end
		
		return nil
	end,
	["inflectcolor"] = function(color)
		if not color then
			return
		end
		return util.inflectColorName(color)
	end,
	["car_id_nearest"] = function(maxDist, maxPlayers)
		maxDist = maxDist or 50
		maxPlayers = maxPlayers or false

		local res, HandleVeh, Distance, posX, posY, posZ, countPlayers = util.GetNearestCarByPed(PLAYER_PED, maxDist, maxPlayers)

		return res and select(2, sampGetVehicleIdByCarHandle(HandleVeh))
	end,
	["car_driver_id"] = function(car_id)
		local res, car = sampGetCarHandleBySampVehicleId(car_id)
		
		if not res then
			return
		end
		local driver = getDriverOfCar(car)

		return driver and select(2, sampGetPlayerIdByCharHandle(driver))
	end,
	["player_id_nearest"] = function(maxDist)
		maxDist = maxDist or 50
		
		local nearest = util.getNearestPedByPed(PLAYER_PED, maxDist)

		return nearest and select(2, sampGetPlayerIdByCharHandle(nearest)) or nil
	end,
	["server_name"] = function()
		return sampGetCurrentServerName()
	end,
	["server_ip"] = function()
		return sampGetCurrentServerAddress()
	end,
	["arizona_server_number"] = function()
		local server = servers[sampGetCurrentServerAddress()]

		return server and server.number or 0
	end,
	["arizona_server_name"] = function()
		local server = servers[sampGetCurrentServerAddress()]

		return server and server.name or "����������"
	end,
	["arizona_server_runame"] = function()
		local server = servers[sampGetCurrentServerAddress()]

		return server and server.runame or "����������"
	end,
}
CommandLoader.env_docs = {
	{
		name="concat_params",
		description="��������� ��������� � ������, ������� � N � ���������� N2(�� ��������� �� ����� ����������)",
		params={"������?", "�����?"},
		paste = "~{concat_params(1, 3)}~"
	},
	{
		name="wait",
		description="����� N �����������",
		params={"��"},
		paste = "~{wait(1000)}~"
	},
	{
		name="waitif",
		description="����� N �����������, ���� ������� �������",
		params={"�������", "��"},
		paste = "~{waitif(true, 1000)}~"
	},
	{
		name="time",
		description="���������� ������� ����� � ������� ��:��:��",
		params={},
	},
	{
		name="date",
		description="���������� ������� ���� � ������� ��.��.����",
		params={},
	},
	{
		name="sex",
		description="���������� � ���� ��� ��������� �������, ����� ������ ������",
		params={},
	},
	{
		name="my_gun",
		description="���������� ID ������ ������",
		params={},
	},
	{
		name="my_gun_weapon",
		description="���������� �������� ������ ������",
		params={}
	},
	{
		name="my_lvl",
		description="���������� ������� ������",
		params={}
	},
	{
		name="my_armor",
		description="���������� ����� ������",
		params={}
	},
	{
		name="my_hp",
		description="���������� �������� ������",
		params={}
	},
	{
		name="my_id",
		description="���������� ID ������",
		params={}
	},
	{
		name="my_nick",
		description="���������� ��� ������",
		params={}
	},
	{
		name="my_name",
		description="���������� ��� ������",
		params={}
	},
	{
		name="my_surname",
		description="���������� ������� ������",
		params={}
	},
	{
		name="my_rpnick",
		description="���������� RP-��� ������",
		params={}
	},
	{
		name="my_rpname",
		description="���������� ��� RP-���� ������",
		params={}
	},
	{
		name="my_rpsurname",
		description="���������� ������� RP-���� ������",
		params={}
	},
	{
		name="my_car",
		description="���������� �������� ������ ������",
		params={}
	},
	{
		name="my_carcolor",
		description="���������� ���� ������ ������",
		params={}
	},
	{
		name="my_fps",
		description="���������� FPS",
		params={}
	},
	{
		name="random",
		description="���������� ��������� ����� � ��������� �� N �� N2",
		params={"N", "N2"},
		paste = "~{random(1, 10)}~"
	},
	{
		name="city",
		description="���������� �������� ������, � ������� ��������� �����",
		params={},
	},
	{
		name="street",
		description="���������� �������� �����, �� ������� ��������� �����",
		params={},
	},
	{
		name="nickid",
		description="���������� ��� ������ �� ID",
		params={"ID"},
		paste = "~{nickid(1)}~"
	},
	{
		name="rpnickid",
		description="���������� RP-��� ������ �� ID",
		params={"ID"},
		paste = "~{rpnickid(1)}~"
	},
	{
		name="carid",
		description="���������� �������� ������ ������ �� ID",
		params={"ID"},
		paste = "~{carid(1)}~"
	},
	{
		name="carcolorid",
		description="���������� ���� ������ ������ �� ID",
		params={"ID"},
		paste = "~{carcolorid(1)}~"
	},
	{
		name="inflectcolor",
		description="�������� �������� �����",
		params={"����"},
		paste = "~{inflectcolor(\"�������\")}~"
	},
	{
		name="car_id_nearest",
		description="���������� ID ��������� ������",
		params={"������?", "������������ ���������� ������� ������ ������?"},
		paste = "~{car_id_nearest(50)}~"
	},
	{
		name="car_driver_id",
		description="���������� ID �������� ������",
		params={"ID ������"},
		paste = "~{car_driver_id(1)}~"
	},
	{
		name="player_id_nearest",
		description="���������� ID ���������� ������",
		params={"������"},
		paste = "~{player_id_nearest(50)}~"
	},
	{
		name="server_name",
		description="���������� �������� ������� � ������ ����",
		params={},
	},
	{
		name="server_ip",
		description="���������� IP �������",
		params={},
	},
	{
		name="arizona_server_number",
		description="���������� ����� ������� Arizona RP",
		params={},
	},
	{
		name="arizona_server_name",
		description="���������� �������� ������� Arizona. �������� Phoenix",
		params={},
	},
	{
		name="openMenu",
		description="��������� ����",
		params={"��� ����"},
		paste = "~{openMenu(\"����\")}~"
	},
}

-- ��������� ����� �������:
-- ~{server_name()}~ - ���������� �������� ������� � ������ ����
-- ~{server_ip()}~ - ���������� IP �������
-- ~{arizona_server_number()}~ - ���������� ����� ������� Arizona RP
-- ~{arizona_server_name()}~ - ���������� �������� ������� Arizona. �������� Phoenix

function scanDirectory(directory, scanSubdirs)
	local files = {}
	local dirs = {}
	for file in lfs.dir(directory) do
		if file ~= "." and file ~= ".." then
			local filePath = util.path_join(directory, file)
			local mode = lfs.attributes(filePath, "mode")
			if mode == "file" and file:find(".json$") then
				table.insert(files, file)
			elseif scanSubdirs and mode == "directory" then
				local subdirFiles = scanDirectory(filePath, false)
				if next(subdirFiles) then
					dirs[file] = subdirFiles.files
				end
			end
		end
	end

	return files, dirs
end

CommandLoader.imserializer = {}

function CommandLoader.imserializer.serMenu(menu)
	local tbl = {
		name = imgui.new.char[128](u8(menu.name)),
		description = imgui.new.char[256](u8(menu.description or "")),
		size = {
			x = imgui.new.int(menu.size.x),
			y = imgui.new.int(menu.size.y),
		},
		type = imgui.new.char[128](menu.type),
	}

	if menu.type == CommandLoader.menuTypes.CHOICE then
		tbl.choices = {}
		for _, choice in ipairs(menu.choices) do
			local c = {}
			c.name = imgui.new.char[128](u8(choice.name))
			c.text = imgui.new.char[15360](u8(choice.text))
			table.insert(tbl.choices, c)
		end
	end

	return tbl
end

function CommandLoader.imserializer.deserMenu(menu)
	local tbl = {
		name = u8:decode(ffi.string(menu.name)),
		description = u8:decode(ffi.string(menu.description)),
		size = {
			x = menu.size.x[0],
			y = menu.size.y[0],
		},
		type = ffi.string(menu.type),
	}

	if tbl.type == CommandLoader.menuTypes.CHOICE then
		tbl.choices = {}
		for _, choice in ipairs(menu.choices) do
			local c = {}
			c.name = u8:decode(ffi.string(choice.name))
			c.text = u8:decode(ffi.string(choice.text))
			table.insert(tbl.choices, c)
		end
	end

	return tbl
end

function CommandLoader.imserializer.serParam(param)
	local tbl = {
		name = imgui.new.char[128](u8(param.name)),
		type = imgui.new.char[128](param.type),
		default = imgui.new.char[128](u8(param.default)),
		required = imgui.new.bool(param.required),
	}

	return tbl
end
function CommandLoader.imserializer.deserParam(param)
	local tbl = {
		name = u8:decode(ffi.string(param.name)),
		type = ffi.string(param.type),
		default = u8:decode(ffi.string(param.default)),
		required = param.required[0],
	}

	return tbl
end

function CommandLoader.imserializer.serCommand(command)
	local tbl = {
		name = imgui.new.char[128](u8(command.name)),
		text = imgui.new.char[15360](u8(command.text)),
		description = imgui.new.char[256](u8(command.description or "")),
		enabled = imgui.new.bool(command.enabled),
		params = {},
		menus = {},
	}

	for _, param in ipairs(command.params) do
		table.insert(tbl.params, CommandLoader.imserializer.serParam(param))
	end

	for _, menu in ipairs(command.menus) do
		table.insert(tbl.menus, CommandLoader.imserializer.serMenu(menu))
	end

	return tbl
end
function CommandLoader.imserializer.deserCommand(command)
	local tbl = {
		name = u8:decode(ffi.string(command.name)),
		text = u8:decode(ffi.string(command.text)),
		description = u8:decode(ffi.string(command.description)),
		enabled = command.enabled[0],
		params = {},
		menus = {},
	}

	for _, param in ipairs(command.params) do
		table.insert(tbl.params, CommandLoader.imserializer.deserParam(param))
	end

	for _, menu in ipairs(command.menus) do
		table.insert(tbl.menus, CommandLoader.imserializer.deserMenu(menu))
	end

	return tbl
end

function CommandLoader.imserializer.serNote(note)
	local tbl = {
		name = imgui.new.char[128](u8(note.name)),
		text = imgui.new.char[15360](u8(note.text)),
		enabled = imgui.new.bool(note.enabled),
		pinned = imgui.new.bool(note.pinned),
		openOnStart = imgui.new.bool(note.openOnStart),
		pos = {
			x = imgui.new.int(note.pos.x),
			y = imgui.new.int(note.pos.y),
		},
		size = {
			x = imgui.new.int(note.size.x),
			y = imgui.new.int(note.size.y),
		},
		FPS = imgui.new.float(note.FPS),
	}

	return tbl
end

function CommandLoader.imserializer.deserNote(note)
	local tbl = {
		name = u8:decode(ffi.string(note.name)),
		text = u8:decode(ffi.string(note.text)),
		enabled = note.enabled[0],
		pinned = note.pinned[0],
		openOnStart = note.openOnStart[0],
		pos = {
			x = note.pos.x[0],
			y = note.pos.y[0],
		},
		size = {
			x = note.size.x[0],
			y = note.size.y[0],
		},
		FPS = note.FPS[0],
	}

	return tbl
end

function CommandLoader.imserializer.serSource(source)
	local tbl = {
		name = imgui.new.char[128](u8(source.name)),
		author = imgui.new.char[128](u8(source.author or "")),
		description = imgui.new.char[512](u8(source.description or "")),
		enabled = imgui.new.bool(source.enabled),
		filepath = imgui.new.char[128](source.filepath),
		commands = {},
		notes = {},
	}

	for _, cmd in ipairs(source.commands) do
		table.insert(tbl.commands, CommandLoader.imserializer.serCommand(cmd))
	end

	for _, note in ipairs(source.notes) do
		table.insert(tbl.notes, CommandLoader.imserializer.serNote(note))
	end

	return tbl
end

function CommandLoader.imserializer.deserSource(source)
	local tbl = {
		name = u8:decode(ffi.string(source.name)),
		author = u8:decode(ffi.string(source.author)),
		description = u8:decode(ffi.string(source.description)),
		enabled = source.enabled[0],
		filepath = ffi.string(source.filepath),
		commands = {},
		notes = {},
	}

	for _, cmd in ipairs(source.commands) do
		table.insert(tbl.commands, CommandLoader.imserializer.deserCommand(cmd))
	end

	for _, note in ipairs(source.notes) do
		table.insert(tbl.notes, CommandLoader.imserializer.deserNote(note))
	end

	return tbl
end

function CommandLoader.imserializer.newChooseMenu(tbl)
	tbl = tbl or {}
	return {
		name = tbl.name or imgui.new.char[256]("menu"),
		description = tbl.description or imgui.new.char[256](""),
		type = tbl.type or commandloader.menuTypes.CHOICE,
		size = tbl.size or {
			x = imgui.new.int(200),
			y = imgui.new.int(125),
		},
		choices = tbl.choices or {},
	}
end

function CommandLoader.imserializer.newChooseMenuChoice(tbl)
	tbl = tbl or {}
	return {
		name = tbl.name or imgui.new.char[128](""),
		text = tbl.text or imgui.new.char[15360](""),
	}
end

function CommandLoader.imserializer.newParam(tbl)
	tbl = tbl or {}
	return {
		name = tbl.name or imgui.new.char[128]("param"),
		type = tbl.type or imgui.new.char[128]("string"),
		default = tbl.default or imgui.new.char[128](""),
		required = tbl.required or imgui.new.bool(true),
	}
end

function CommandLoader.imserializer.newCommand(tbl)
	tbl = tbl or {}
	return {
		name = tbl.name or imgui.new.char[256]("cmd" .. #state.currentMsource.commands + 1),
		text = tbl.text or imgui.new.char[15360](""),
		description = tbl.description or imgui.new.char[256](""),
		enabled = tbl.enabled or imgui.new.bool(true),
		params = tbl.params or {},
		menus = tbl.menus or {},
	}
end

function CommandLoader.imserializer.newNote(tbl)
	tbl = tbl or {}
	return {
		name = tbl.name or imgui.new.char[128]("note"),
		text = tbl.text or imgui.new.char[15360](""),
		enabled = tbl.enabled or imgui.new.bool(true),
		pinned = tbl.pinned or imgui.new.bool(false),
		openOnStart = tbl.openOnStart or imgui.new.bool(false),
		pos = tbl.pos or {
			x = imgui.new.int(100),
			y = imgui.new.int(100),
		},
		size = tbl.size or {
			x = imgui.new.int(100),
			y = imgui.new.int(100),
		},
		FPS = tbl.FPS or imgui.new.float(0.0),
	}
end

function CommandLoader.newSource(tbl)
	tbl = tbl or {}
	return {
		name = tbl.name or ("profile" .. #CommandLoader.sources + 1),
		description = tbl.description or "",
		enabled = tbl.enabled or true,
		filepath = tbl.filepath or util.path_join(
			getWorkingDirectory(),
			commandloader.dir,
			"profile" .. tostring(#commandloader.sources + 1) .. ".json"
		),
		commands = tbl.commands or {},
		notes = tbl.notes or {},
	}
end

---@param source CommandSource
---@param filename string
---@return CommandSource
function CommandLoader.validateSource(source, filename)
	local hasErrors = false
	if isEmpty(source.name) then
		hasErrors = true
		print("Source name is empty in file " .. filename)
	end

	if source.enabled == nil then
		source.enabled = true
	end

	if not source.commands then
		source.commands = {}
	end

	for i, cmd in ipairs(source.commands) do
		local command = CommandLoader.validateCommand(cmd)
		source.commands[i] = command
	end

	if not source.notes then
		source.notes = {}
	end

	for i, note in ipairs(source.notes) do
		local note = CommandLoader.validateNote(note)
		source.notes[i] = note
	end

	return source
end

---@param command table
---@return Command
function CommandLoader.validateCommand(command)
	local hasErrors = false

	if isEmpty(command.name) then
		hasErrors = true
		print(string.format("Command has no name"))
	end

	if isEmpty(command.text) then
		hasErrors = true
		print(string.format("Command %s has no text", command.name))
	end

	if command.enabled == nil then
		command.enabled = true
	end

	if command.params then
		for i, param in ipairs(command.params) do
			if isEmpty(param.name) then
				hasErrors = true
				print(string.format("Param %s has no name in command %s", i, command.name))
			end

			if not param.type then
				param.type = "string"
			end

			if not param.required then
				param.required = true
			end

			if not isEmpty(param.default) and param.required then
				param.required = false
			end

			if not CommandLoader.typeProcessor[param.type] then
				hasErrors = true
				print(string.format("Param %s has no type in command %s", param.name, command.name))
			end
		end
	else
		command.params = {}
	end

	if command.menus then
		for i, menu in ipairs(command.menus) do
			if menu.type == CommandLoader.menuTypes.CHOICE then
				if not menu.choices then
					menu.choices = {}
				end
				for j, choice in ipairs(menu.choices) do
					if isEmpty(choice.name) then
						hasErrors = true
						print(string.format("Choice %s has no name in menu %s in command %s", j, menu.name, command.name))
					end

					if not choice.text then
						choice.text = ""
					end
				end
			else
				hasErrors = true
				print(string.format("Menu %s has unknown type in command %s", menu.name, command.name))
			end
		end
	else
		command.menus = {}
	end

	if hasErrors then
		command.enabled = false
	end

	return command
end

---@param note Note
function CommandLoader.validateNote(note)
	if isEmpty(note.name) then
		note.name = "Note"
	end

	if note.enabled == nil then
		note.enabled = true
	end

	if note.pinned == nil then
		note.pinned = false
	end

	if note.openOnStart == nil then
		note.openOnStart = false
	end

	if not note.pos then
		note.pos = {x = 100, y = 100}
	end

	if not note.size then
		note.size = {x = 100, y = 100}
	end

	if not note.FPS then
		note.FPS = 0
	end

	return note
end

function CommandLoader.processFile(filePath)
	local file = io.open(filePath, "r")
	if not file then
		error("Failed to open file: " .. filePath)
		return
	end

	local content = file:read("*a")
	file:close()
	local success, data = pcall(decodeJson, content)

	if not success then
		print("Failed to parse file " .. filePath)
		return
	end
	if data then
		local source = CommandLoader.validateSource(data, filePath)

		source.filepath = filePath
		table.insert(CommandLoader.sources, source)
	end
end

function CommandLoader.load()
	local files, dirs = scanDirectory(util.path_join(getWorkingDirectory(), CommandLoader.dir), true)
	CommandLoader.processFiles(files, CommandLoader.dir)

	for dir, files in pairs(dirs) do
		local directory = util.path_join(CommandLoader.dir, dir)
		CommandLoader.processFiles(files, directory)
	end
end

function CommandLoader.reload()
	CommandLoader.unregisterCommands()
	CommandLoader.sources = {}
	CommandLoader.load()
	CommandLoader.registerCommands()
end

function CommandLoader.processFiles(files, directory)
	for _, file in ipairs(files) do
		local filePath = util.path_join(getWorkingDirectory(), directory, file)
		CommandLoader.processFile(filePath)
	end
end

function CommandLoader.saveSource(source)
	local file = io.open(source.filepath, "w")
	if not file then
		print("Failed to open file " .. source.filepath)
		return
	end

	source.filepath = nil
	local data = encodeJson(source)
	file:write(data)
	file:close()
end

function CommandLoader.removeSource(source)
	os.remove(source.filepath)
end

function CommandLoader.findSourceByName(name)
	for _, source in ipairs(CommandLoader.sources) do
		if source.name == name then
			return source
		end
	end
end

function CommandLoader.iterateCommands()
	return coroutine.wrap(function()
		for _, source in ipairs(CommandLoader.sources) do
			for _, cmd in ipairs(source.commands) do
				coroutine.yield(cmd)
			end
		end
	end)
end

function CommandLoader.unregisterCommands()
	for cmd in CommandLoader.iterateCommands() do
		sampUnregisterChatCommand(cmd.name)
	end
end

local cmdstate = {
	---@type {waitf: number, waitm: number, stop: boolean}[]
	cmds = {},
}

function CommandLoader.processLine(iter, env)
	local line
	if type(iter) == "string" then
		line = iter
	else
		line = iter()
	end

	if not line then
		return false
	end

	-- if line contain ~{ but not contain }~ then we need to concat lines
	while line and line:find("~{") and not line:find("}~") do
		line = line .. "\n" .. iter()
	end

	local func
	line = line:gsub("~{(.-)}~", function(expr)
		-- if expression is multiline, we need to add return at begin of end line if it's not present
		
		--check for multiline and modify last line
		if expr:find("\n") then
			local lines = {}
			for l in expr:gmatch("[^\r\n]+") do
				table.insert(lines, l)
			end
			local last = lines[#lines]
			if not last:match("^%s*[%w_]+%s*=%s*") and not last:match("^%s*return%s+") then
				lines[#lines] = "return " .. last
			end
			expr = table.concat(lines, "\n")
		elseif not expr:match("^%s*[%w_]+%s*=%s*") and not expr:match("^%s*return%s+") then
			expr = "return "..expr
		end

		local prot = sandbox.protect(expr, {
			env = env
		})
		local ok, result = pcall(prot)
		
		if not ok then
			print(result)
			sampAddChatMessage(result, -1)
			return ""
		end
		func = prot
		return tostring(result or "")
	end)
	return line, func
end

function CommandLoader.registerCommands()
	for _, source in ipairs(CommandLoader.sources) do
		for _, cmd in ipairs(source.commands) do
			if source.enabled and not cmd.hasErrors and cmd.enabled then
				sampRegisterChatCommand(cmd.name, function(params)
					if params == "/stop" and cmdstate.cmds[cmd.name] then
						cmdstate.cmds[cmd.name].stop = true
						return
					end
					
					if cmdstate.cmds[cmd.name] then
						chat_error("������� " .. cmd.name .. " ��� �����������")
						chat_error("���� �� ������ �������� ����������, ������� /" .. cmd.name .. " /stop")
						return
					end

					local args = {}
					local aparam = string.gmatch(params, "[^%s]+")
					local vararg = false
					local varargname = nil
					for _, pdata in pairs(cmd.params) do
						local ap = aparam()

						if not ap and pdata.required then
							chat_info(cmd.name..": �������������: " .. generateUsage(cmd.name, cmd.params))
							return
						elseif not ap then
							args[pdata.name] = pdata.default or ""
							break
						end

						if pdata.type == "vararg" then
							args[pdata.name] = ap
							vararg = true
							varargname = pdata.name
							break
						end

						local proc = CommandLoader.typeProcessor[pdata.type]

						local arg, err = proc(ap)
						if not arg then
							sampAddChatMessage(cmd.name..": "..err, -1)
							return
						end

						args[pdata.name] = arg
					end
					if vararg then
						for ap in aparam do
							args[varargname] = args[varargname] .. " " .. ap
						end
					end
				
					cmdstate.cmds[cmd.name] = {}

					local env = util.merge(args, cfg.general, CommandLoader.env, {
						v = {}
					})
					
					local function processLines(text, s)
						local i = 1
						local iter = text:gmatch("[^\r\n]+")

						function env.wait(m)
							s.waitm = tonumber(m) or false
						end

						function env.waitif(cond, m)
							if cond then
								s.waitf = tonumber(m or 50)
							else
								s.waitf = false
							end
						end

						function env.stop()
							s.stop = true
						end

						while not s.stop do
							line, func = CommandLoader.processLine(iter, env)
							if line == false then
								s.stop = true
								break
							end

							while s.waitf and not s.stop do
								wait(s.waitf)
								func()
							end

							if s.waitm then
								wait(s.waitm)
								s.waitm = nil
							elseif i > 1 and not isEmpty(line) then
								wait(cfg.general.default_delay)
							end

							if line and not isEmpty(line) then
								i = i + 1
								sampProcessChatInput(line)
							end
						end

						if s.stop then
							s = nil
							cmdstate.cmds[cmd.name] = nil
						end
					end

					function env.openMenu(name)
						---@type Menu
						local menu = util.findByField(cmd.menus, "name", name)
						if not menu then
							error("Menu not found: " .. name)
						end
						
						if menu.type == CommandLoader.menuTypes.CHOICE then
							table.insert(state.menus, util.merge(menu, {
								render = imgui.new.bool(true),
								onChoice = function (choice)
									env.choice = choice.name
									lua_thread.create(function()
										processLines(choice.text, {})
									end)
								end
							}))
						end
					end

					function env.concatParams(start, finish)
						local start = start or 1
						local finish = finish or #args

						local result = ""
						for i = start, finish do
							result = result .. args[i] .. " "
						end

						return result
					end
					
					lua_thread.create(function()
						processLines(cmd.text, cmdstate.cmds[cmd.name])
					end)
				end)
			end
		end
	end

	sampRegisterChatCommand("eval", function(params)
		local ok, result = xpcall(sandbox.run, debug.traceback, "return "..params, {
			env = util.merge(cfg.general, CommandLoader.env),
		})

		if not ok then
			print(result)
		end

		sampAddChatMessage(tostring(result), -1)
	end)
end

function CommandLoader.sourceCount()
	return #CommandLoader.sources
end

function CommandLoader.commandCount()
	local count = 0
	for _ in CommandLoader.iterateCommands() do
		count = count + 1
	end
	return count
end

return CommandLoader
