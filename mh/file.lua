local lfs = require("lfs")
local print= require("mh.print")
local _ = require("mh.gettext")

local fs = {__name="file"}

local function getFileExtension(filename)
    return filename:match("^.+%.(.+)$")  -- Extracts the part after the last dot (.)
end

function fs.getFiles(directory,ext,recursive)
	recursive = recursive or false
	local files = {}
    for file in lfs.dir(directory) do
        -- Ignore "." and ".."
        if file ~= "." and file ~= ".." then
            local fullPath = directory .. "/" .. file            
            local mode = lfs.attributes(fullPath, "mode")
            if mode == "file" then
				if ext == getFileExtension(file) then
					print(fullPath)  -- This is a file
					table.insert(files,fullPath)
				end
			elseif recursive and mode == "directory" then 
				for _,f in ipairs(fs.getFiles(fullPath,ext,recursive)) do
					table.insert(files,f)
				end
            end
        end
    end
    return files
end


function fs.createDirectory(dir,recreate)
	if recreate==nil then recreate=false end
	local mode = lfs.attributes(dir, "mode")
	print(mode)
	if mode == "directory" then
		print.i(string.format(("Directory %s already exists"),dir))
	elseif mode == nil then 
		lfs.mkdir(dir) 
	elseif mode == "file" then
		print.e(string.format(("%s already exists as a file"),dir))
	end
end

local function normalize_path(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        if part == ".." then
            table.remove(parts)  -- Go up one directory
        elseif part ~= "." then
            table.insert(parts, part)  -- Keep valid parts
        end
    end
    return "/" .. table.concat(parts, "/")
end

function fs.absolute_path(rel_path)
    if rel_path:sub(1,1)=='/' then return normalize_path(rel_path) end
    local current = lfs.currentdir()  -- Get current directory
    return normalize_path(current .. "/" .. rel_path)
end


if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
	--for _,f in pairs(fs.getFiles(".","lua")) do print(f) end
	--fs.createDirectory("./lua",true)
	
	local fullpath = fs.absolute_path("../../jk/lm")
	print(fullpath)
	fullpath = fs.absolute_path("./../jk/lm")
	print(fullpath)
	fullpath = fs.absolute_path("/home/marc")
	print(fullpath)
	for _,f in ipairs(fs.getFiles("/home/marc/Nextcloud","lua",true)) do print(f) end

else
	return fs
end
