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

local print = print
if options.q then
    print = function() end
end

------------------------------------

local function getFilePathToRead(argNumber)
    local path = shell.resolve(args[argNumber] or (function()
        io.stderr:write("check args!\n")
        os.exit()
    end)())
    if not path or not fs.exists(path) then
        io.stderr:write("file not found\n")
        os.exit()
    elseif fs.isDirectory(path) then
        io.stderr:write("is directory\n")
        os.exit()
    end
    return path
end

local function getFilePathToWrite(argNumber)
    local path = shell.resolve(args[argNumber] or (function()
        io.stderr:write("check args!\n")
        os.exit()
    end)())
    if fs.isDirectory(path) then
        io.stderr:write("directory exists\n")
        os.exit()
    elseif fs.exists(path) and not options.f then
        io.stderr:write("file already exists\n")
        os.exit()
    end
    return path
end

local function yesno(text)
    if options.y then
        print(text .. " [Y/n] y")
    else
        if not options.q then io.write(text .. " [Y/n] ") end
        local data = io.read()
        return data and data:lower() == "y"
    end
end

local function isReadonly(address)
    print(">> checking readonly: " .. address)
    local ro = not not select(2, component.invoke(address, "set", component.invoke(address, "get")))
    if ro then
        print(">> eeprom chip " .. address .. " is readonly")
    end
    return ro
end

local function findEeprom()
    print(">> finding eeprom")
    if component.isAvailable("eeprom") then
        print(">> finded eeprom " .. component.eeprom.address)
        return component.eeprom
    end
    io.stderr:write(">> eeprom is not found\n")
    io.stderr:write(">> exit.\n")
    os.exit()
end

------------------------------------

local function dump()
    local filepath = getFilePathToWrite(2)

    local eeprom = findEeprom()
    if yesno("create dump?") then
        local dump = {}

        print(">> dumping eeprom main code")
        dump.main = eeprom.get()
        print(">> dumping eeprom-data")
        dump.data = eeprom.getData()
        print(">> dumping readonly state")
        dump.readonly = isReadonly(eeprom.address)
        print(">> dumping label")
        dump.label = eeprom.getLabel()

        print(">> saving file " .. filepath)
        local file = assert(io.open(filepath, "wb"))
        file:write(assert(serialization.serialize(dump)))
        file:close()
        print("completed.")
    end
end

local function flash()
    local filepath = getFilePathToRead(2)

    local eeprom = findEeprom()
    if not isReadonly(eeprom.address) then
        print(">> reading file " .. filepath)
        local file = assert(io.open(filepath, "rb"))
        local eepromfile = assert(serialization.unserialize(file:read("*a")))
        file:close()
        if yesno("flash eeprom?" .. (eepromfile.readonly and " IT WILL IRREVERSIBLY BECOME READONLY" or "")) then
            print(">> flashing main code")
            eeprom.set(eepromfile.main or "")

            print(">> flashing data")
            eeprom.setData(eepromfile.data or "")

            print(">> setting label")
            eeprom.setLabel(eepromfile.label or "eeprom")
            
            if eepromfile.readonly then
                print(">> making readonly")
                eeprom.makeReadonly(eeprom.getChecksum())
            end

            print("completed.")
        end
    else
        io.stderr:write("aborted: eeprom is readonly")
    end
end

------------------------------------

if args[1] == "flash" then
    flash()
elseif args[1] == "dump" then
    dump()
else
    io.stderr:write("unknown mode.")
end 