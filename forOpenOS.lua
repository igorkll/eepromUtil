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

------------------------------------

local function getFilePath(argNumber)
    local path = shell.resolve(args[argNumber])
    if not path or not fs.exists(path) then
        io.stderr:write("file not found\n")
    elseif fs.isDirectory(path) then
        io.stderr:write("is directory\n")
    end
    return path
end

local function yesno(text)
    if options.y then
        if not options.q then print(text .. " [Y/n] y") end
    else
        if not options.q then io.write(text .. " [Y/n] ") end
        local data = io.read()
        return data and data:lower() == "y"
    end
end

local function isReadonly(address)
    if not options.q then print(">> checking readonly: " .. address) end
    local ro = not pcall(component.invoke, address, "set", component.invoke(address, "get"))
    if ro then
        if not options.q then print(">> eeprom chip " .. address .. " is readonly") end
    end
    return ro
end

local function findEeprom()
    if not options.q then print(">> finding eeprom") end
    if component.isAvailable("eeprom") then
        if not options.q then print(">> finded eeprom " .. component.eeprom.address) end
        return component.eeprom
    end
    if not options.q then
        io.stderr:write("eeprom is not found\n")
        io.stderr:write("exit.\n")
    end
    os.exit()
end

------------------------------------

local function dump()
    local eeprom = 
end

------------------------------------

