local shell = require("shell")
local fs = require("filesystem")

local args, options = shell.parse(...)
local path = shell.resolve(args[1])
if not path or not fs.exists(path) then
    io.stderr:write("file not found\n")
elseif fs.isDirectory(path) then
    io.stderr:write("is directory\n")
end

------------------------------------

