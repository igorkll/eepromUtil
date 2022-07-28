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

local function getFilePathToRead(argNumber)
    local path = shell.resolve(args[argNumber])
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
    local path = shell.resolve(args[argNumber])
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
        io.stderr:write(">> eeprom is not found\n")
        io.stderr:write(">> exit.\n")
    end
    os.exit()
end

------------------------------------

local function dump()
    local eeprom = findEeprom()
    if yesno("create dump?") then
        local dump = {}

        print(">> dumping eeprom main code")
        dump.main = eeprom.get()
        print(">> dumping eeprom-data")
        dump.data = eeprom.getData()
        print(">> dumping readonly state")
        dump.readonly = isReadonly(eeprom.address)

        print(">> saving file")
        local file = io.open(getFilePathToWrite(2), "wb")
        file:write(assert(serialization.serialize(dump)))
        file:close()
        print("completed.")
    end
end

local function flash()
    local eeprom = findEeprom()
    if not isReadonly(eeprom.address) then
        print(">> reading file")
        local file = io.open(getFilePathToRead(2), "wb")
        local eepromfile = assert(serialization.unserialize(file:read("a*")))
        file:close()
        if yesno("flash eeprom?" .. (eepromfile.readonly and " IT WILL IRREVERSIBLY BECOME READONLY" or "")) then
            print(">> flashing main code")
            eeprom.set(eepromfile.main)

            print(">> flashing data")
            eeprom.setData(eepromfile.data)
            
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
elseif args[1] == "a" then
    dump()
else
    io.stderr:write("unknown mode.")
end