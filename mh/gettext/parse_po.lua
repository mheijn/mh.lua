local parser={__name="po parser"}

local print=require("mh.print")
require("mh.string")
--util=require("gramps.util")

local fs =require("mh.file")

local function unquote(s)
	str=""
	for m in s:gmatch('"(.-)"') do
		str=str..m
	end
	--print(s,"->",str)
	return(str)
end

---
-- Scan lines in po-file
local function parse_table(lines)
	local id=""
	local id_plural=""
	local str=""
	local strmulti={}
	local locator=""
	
	local strings={}
	local index={}

	for _,line in pairs(lines)do 
		--print(line)
		
		local s =line:match("^%s*msgid%s(.+)")
		if s then 
			--print(locator)
			if locator=="id_plural" then print.e('plural before sinle id')
			elseif type(locator)=="string"  then
				--print.i(string.format('last one is str %s %s',id,str))
				table.insert(strings,{id,str})
				index[id]=#strings
			else
				--print.i('last one is str[1]')
				table.insert(strings,{{id,id_plural},strmulti})
				index[id]=#strings
				index[id_plural]=#strings
			end
			id="";id_plural="";str="";strmulti={}
			id=unquote(s)
			locator = "id"
			goto continue
		end
		
		s = line:match("^%s*msgid_plural%s(.+)")
		if s then 
			if locator~="id" then print.e('plural not  after sinle id') end
			id_plural=unquote(s)
			locator = "id_plural"
			goto continue
		end

		s = line:match("^%s*msgstr%s(.+)")
		if s then 
			str=unquote(s)
			locator="str"
			goto continue
		end
		nr, s = line:match("^%s*msgstr%[(%d+)%]%s*[=%s]%s*(.+)")
		--print(nr,s,line)
		if s then 
			locator=tonumber(nr)+1
			strmulti[locator]=unquote(s)
			goto continue
		
		--s = line:match("^%s*msgstr%[1%]%s(.+)")
		--if s then 
		--	str1=unquote(s)
		--	locator="str1"
		--	goto continue
		
		else
			if locator == "id" then id=id..unquote(line) 
			elseif locator == "id_plural" then id_plural=id_plural..unquote(line) 
			elseif locator == "str" then str=str..unquote(line) 
			elseif strmulti[locator] then  strmulti[locator] = strmulti[locator]..unquote(line)
			--elseif locator == "str1" then str1=str1..unquote(line) 
			end
		end
		::continue::
		--print.i("locator is "..locator)
    end
	if 0 < #id then 
        --print(id,str,id_plural,strmulti)
		--print(type(locator),locator)
		if locator=="str" then
			table.insert(strings,{id,str})
			index[id]=#strings
		else
            --print(locator,type(locator))
			table.insert(strings,{{id,id_plural},strmulti})
			--for i,k in ipairs(strmulti) do print(i,k) end
			index[id]=#strings
			index[id_plural]=#strings
		end
	end
	--print("POFILE",util.dump(strings))
	return strings, index
end 

---
-- Sacn LUA file
local function scan_file(filename,strings,index) 
	local strings = strings or {}
	local index = index or {}
	
	local file = io.open(filename, "r")	
	if not file then print.e("Error: Could not open file!") return "" end
	local content = file:read("*all")
	file:close()
	
	table.insert(strings,{"###",filename})
	for mat in content:gmatch('_%((.-)%)') do
		--print(mat)
		local m1,m2,m3 = mat:match('%s*"(.-)"%s*,%s*"(.-)"%s*,%s*([%d.]*)%s*')
		if m1 then 
			--print("match",m1,m2,"["..m3.."]")
			if not index[m1] or not index[m1] then
				table.insert(strings,{{m1,m2},{"",""}})
				index[m1]=#strings
				index[m2]=#strings
			end
		else 
			local m = mat:match('%s*"(.-)"%s*')
			if m then 
				if not index[m] then
					table.insert(strings,{m,""})
					index[m]=#strings
				end
			end
		end
	end
	return strings, index
end

local function write_po(filename,strings,index,strings_base)
	strings_base = strings_base or strings
	local file = io.open(filename, "w")	
	
	if not file then print.e(string.format("Error: Could not open file %s!"),filename) return "" end
	if type(strings_base)~="table" then print.e(string.format("Could not write 'string_bas' (not table) to %s",filename)) end
	
	for k,v in pairs(strings_base) do
	
		if v[1] == "###" then file:write('# '..v[2]..'\n')
			
		elseif type(v[1])=="table"then
			local n=index[v[1][1]]
			if n then v=strings[n] end
			file:write('msgid "'..v[1][1]..'"\n')
			file:write('msgid_plural "'..v[1][2]..'"\n')
			for i,vi in ipairs(v[2]) do
				file:write(string.format('msgstr[%d] "%s"\n',i-1,vi))
			end
		else
			local n=index[v[1]]
			if n then v=strings[n]; end
			--if type(v[1])~= "string" then print(util.dump(v)) end
					
			file:write('msgid "'..v[1]..'"\n')
			file:write('msgstr "'..v[2]..'"\n')
		end
	end
	file:close()
	return content 
end


--[[    PARSER    ]]--
function parser.parser(a)
	if type(a)=="table" then 
		return parse_table(a)
	end
	
	local file = io.open(fs.absolute_path(a), "r")	
	if file then
		local lines = {}
		for line in file:lines() do table.insert(lines,line) end
		return parse_table(lines)
	
	else
		print.i(string.format("File %s not found. Try to parse string",fs.absolute_path(a)))
		return parse_table(a:split("\n"))
	end
end

function parser.scanfiles(dir,recursive,languages)
	local strings={}; local index={}
	local path = fs.absolute_path(dir)
	local files = fs.getFiles(path,"lua",recursive)
	
	for _,f in ipairs(files) do 
		print(f)
		strings, index = scan_file(f,strings,index)
	end
	--print(util.dump(strings))
	
	fs.createDirectory(path.."/po")
	write_po(path.."/po/lua.pot",strings,index)
	
	for _,l in ipairs(languages) do 
		--print("TAAL:",l)
		local lan_strings, lan_index = parser.parser(path.."/po/"..l..".po")
		--for i,v in ipairs(lan_strings) do print(v[1],v[2]) end
		write_po(path.."/po/"..l..".po",lan_strings,lan_index,strings)
	end
	
end
return parser
--gmatch("A([^A]*)") do
