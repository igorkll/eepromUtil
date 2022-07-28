local shell = require("shell")
local fs = require("filesystem")
local serialization = require("serialization")
local component = require("component")

local args, options = shell.parse(...)

if #args == 0 then
    print("Usage:")
    print(" - 'eeprom flash <filepath>' flash .eeprom file to eeprom chip")
    print(" - 'eeprom dump <savepath>' dump eeprom to .eeprom file")
    print(" -f: Force overwriting existing files.")
    print(" -y: automatically agree to everything.")
    print(" -q: Quiet mode - no status messages.es.")
    return
end

local path = shell.resolve(args[1])
if not path or not fs.exists(path) then
    io.stderr:write("file not found\n")
elseif fs.isDirectory(path) then
    io.stderr:write("is directory\n")
end

------------------------------------

local function yesno(text)
    io.write(text .. "? [Y/n] ")
    local data = io.read()
    return data and data:lower() == "y"
end

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

local function dump()
    
end

------------------------------------

