if not gettext then


    --print("load GetText")
	gettext={__index=gettext,__name="mygettext",strings = {},index={}}
	
	local parser = require("mh.gettext.parse_po")
	local ml = require("mh.local")
	local textext = require("mh.gettext.textext")
	gettext['local']=ml.language()
	local util=require("gramps.util")

	gettext.module_dirs={"."}

	function gettext.setDirectory(module_dir)
		table.insert(gettext.module_dirs,module_dir)
	end

	local function load_local(lan)
		if lan == nil then lan = gettext['local'] end
		gettext.strings={}
		gettext.index={}
        for i,d in ipairs(gettext.module_dirs) do
            gettext.strings[i], gettext.index[i] = parser.parser(d.."/po/"..lan..".po")
        end

		--for k,v in pairs(gettext.index) do print("index:",v,k) end
		--for k,v in ipairs(gettext.strings) do print("str:",k,v[1],v[2]); if type(v[2])=="table" then print("multi:",v[1][1],v[1][2],v[2][1],v[2][2]); end end
	end

	local function escape(s)
		local se
		if s then 
			se=s:gsub("\n","\\n")
			se=se:gsub("\t","\\t")
		end
		return se
	end
	local function unescape(s)
		local se
		if s then 
			se=s:gsub("\\n","\n")
			se=se:gsub("\\t","\t")
		end
		return se
	end
	
	function gettext.T(s)
		if tex then
			return textext.text(s)
		else
			return s
		end
	end
	
	function gettext.gettext(s1,s2,v) 
		if #gettext.index ~= #gettext.module_dirs or 	gettext['local']~=ml.language() then
            gettext['local']=ml.language()
            load_local()
		end

		local se1 = escape(s1)
		local se2 = escape(s2)
		
		for k,index in ipairs(gettext.index) do
            local i = index[se1]

            --print(k,i,v,se1,se2,#gettext.index)
            if i then
                local strings = gettext.strings[k]

                if v== nil then
                    local s
                    if type(strings[i][2])=="table" then
                        print.e(string.format("Error in gettext %s found in %s",
                            se1,gettext.module_dirs[k]))
                        s = unescape(strings[i][2][1])
                    else
                        s = unescape(strings[i][2])
                    end
                    if 0<#s then return s else return s1 end
                else
                    local strs = strings[i][2]
                    local s
                    if v+1 > #strs then s=strs[#strs] else s=strs[v+1] end
                    --print(s,s1,s2,v,#strs,util.dump(strings[i][2]))
                        local s = unescape(s)
                        if 0<#s then
                            return string.format(s,v)
                        else
                            if v > 1 then
                                return string.format(s2,v)
                            else
                                return string.format(s1,v)
                            end
                        end
                end
            end
        end  --s1 not found
        if v==nil then return s1
        else
            if v>1 then return string.format(s2,v)
            else return string.format(s1,v) end
        end
	end

	function gettext.dngettext(str_one,str_multi,count)
		if count == 1 then
			return string.format(str_one,count)
		else
			return string.format(str_multi,count)
		end
	end
	
	function gettext.run(...)
		local args = {...}
		for i,v in ipairs(args) do print(i,v) end
		
		local arguments = require("mh.arguments")
		arguments.program({description=""})
		arguments.add_argument('make',{help='creates po and poh files'})
		arguments.add_argument('-d','--dir',{default=".",help='directory to find lua-files and create po-derectory'})
		arguments.add_argument('-r','--recursive',{action="store_true",help='search recursive lower directories'})
		arguments.add_argument('-l','--language',{default="",type="array",help='update the language file xx.po as comma sep. array: nl,en,fr'})
		
		--for i,v in ipairs(args) do print(v) end
		
		arguments.parse(args)
		for k,v in pairs(arguments.args) do print(k,v) end

		
		if arguments.get('make') then 
		
			--print('do make',arguments.get('make'))
			--print('dir',arguments.get('dir'))
			--print(arguments.get('language'))
			--for i,lan in ipairs(arguments.get('language')) do print("lan "..i,lan) end
			
			parser.scanfiles(arguments.get('dir'),arguments.get('recursive'),arguments.get('language'))
		end
	end
	
	setmetatable(gettext, {
		__call = function(_,s1,s2,v)
			return gettext.gettext(s1,s2,v)
		end,
	})
	
end
if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
		gettext.run('make')
else
		return gettext
end
