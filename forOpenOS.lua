local shell = require("shell")
local fs = require("filesystem")
local serialization = require("serialization")
local component = require("component")

local args, options = shell.parse(...)

if #args == 0 then
    print("eeprom flash <.eeprom file>; flash .eeprom file to eeprom chip")
    print("eeprom dump")
    return
end

local path = shell.resolve(args[1])
if not path or not fs.exists(path) then
    io.stderr:write("file not found\n")
elseif fs.isDirectory(path) then
    io.stderr:write("is directory\n")
end

------------------------------------

local function findEeprom()
    print("finding eeprom")
    if component.isAvailable("eeprom") then
        print("finded eeprom " .. component.eeprom.address)
        return component.eeprom
    end
    print("eeprom is not found")
    print("exit.")
    os.exit()
end

------------------------------------