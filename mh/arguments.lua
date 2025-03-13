local print = require('mh.print')
require('mh.string')

local function merge(tab1,tab2)
	for k,v in pairs(tab2) do tab1[k]=v end 
end

local Arg = {__name="arguments",__index=arg}

Arg.info = {prog=arg[0],description='',epilog=''}
Arg.arguments={
	{short='h',long='help',help='print this help'},
	{short='d',long='debug',default='error', choices={'error','warning','info','debug'},help='Log level'},
	{long='123',default='global',choices={'global'},help=''}
	}
Arg.args = {}
Arg.commands = {}


function Arg.program(info)	merge(Arg.info,info)  end

--[[
	
	Arg.add_argument('-d','--debug',{default='error', choices={'error','warning','info','debug'}},help='Log level'})
	parser.add_argument('-n','--new',{action="store_true",help='Give unknown devices'})
	parser.add_argument('-i','--incomplete',{action="store_true",help='Give incomplete devices'})
	parser.add_argument('-c','--correct',action="store_true",help='Give correct devices')
	parser.add_argument('-s','--store',action="store_true",help='Give store devices')
	parser.add_argument('-m','--mqtt',action="store_true",help='Activate and send via MQTT')
	parser.add_argument('-t','--time',default=10,type=int,help='Collection time (s) default: 10')
	parser.add_argument('-f','--output',default="",type=str,help='Output scan to file (default stdio)')
]]--

function Arg.add_argument(...)
	local args = {...}
	local ar = {}
	for _,v in pairs(args) do
		--print(v)
		if type(v)=="string" then 
			if v:sub(1,2)=='--' then ar['long']=v:sub(3)
			elseif v:sub(1,1)=='-' then ar['short']=v:sub(2)
			else ar['command']=v
			end
		else
			merge(ar,v)
		end
	end
	if ar.long then 
		local value=""
		if (ar.action) then value = ar.action == "store_true" 
		elseif (ar.default)	then value = ar.default end
		Arg.args[ar.long]=value
	end
	if ar.command then 		
		Arg.args[ar.command]=false
		table.insert(Arg.commands,ar.command) 
	end
	--for k,v in pairs(ar) do print (k,v) end
	table.insert(Arg.arguments,ar)
end

function Arg.help()
	local s="\n"..Arg.info.prog..":"..Arg.info.description
	
	local sc = ""
	local so = ""
	for _,a in pairs(Arg.arguments) do
		if a.command then 
			sc=sc..string.format("\n    %-15s: %s",a.command,a.help)  
		else
			so=so.."\n    "
			if a.short then so=so..string.format("-%1s, ",a.short) end
			if a.long then 	so=so..string.format("--%-9s",a.long) end
			if not a.short then so=so..string.format("%4s"," ") end
			if not a.long then 	so=so..string.format("%11s"," ") end
			so=so..string.format(": %s",a.help) 
			
			sr=""
			if a.type then sr=sr .."type:"..a.type..", " end
			if a.default then sr=sr..'default:'..a.default..", "  end
			if a.choices then sr=sr.."choices:{"
				for _,v in pairs(a.choices) do sr=sr..v..","  end
				sr=sr.."}, "
			end
			if a.action then
				if a.action=="store_true" then sr=sr.."bool, default:false" end
				if a.action=="store_false" then sr=sr.."bool, default:true" end
			end
			if 0<#sr then so=string.format("%s\n%22s(%s)",so," ",sr) end
		end
	end
	if 0 < #sc then s=s.."\n  COMMANDS="..sc end
	if 0 < #so then s=s.."\n  OPTIONS="..so end
	
	s=s..Arg.info.epilog
	return s
end

function next_arg_extra(args,i)
	if #args<= i then return false end 
	if args[i+1].sub(1,2) == '-' then return false end
	return true
end

function Arg.parse(args)
	i=1
	while(args[i]) do
		local t,a,ar,as,found=false
		a=args[i]
		--print("arg "..i,a)
		
		if a:sub(1,2)=="--" then t='long'; as=a:sub(3)
		elseif a:sub(1,1)=="-" then t='short'; as=a:sub(2,2)
		else t='command'; as=a:sub(1) end
		
		for _,ar in pairs(Arg.arguments) do
			--print(t,ar[t],as)
			if ar[t]==as then
				found=true
				if ar.long=='help' then print(Arg.help()); os.exit() 
--				elseif ar.long=='debug'then
				elseif ar.long=='123' then 
					--print("extra 123")
					if next_arg_extra(args,i) then 	i=i+1; Arg.extra(arg[i]);  
					else Arg.extra(ar.default) 
					end
				elseif ar.action then Arg.args[ar.long] = not (ar.action == "store_true")
				elseif t=="command" then Arg.args[as]=true
				elseif (#args <= i) then 
					print.e("Error in arguments")
					found=false
				else
					i=i+1; Arg.args[ar.long]=args[i] 
				end
				break
			end
		end
		if not found then print(Arg.help()); os.exit(1) end
		i=i+1
	end
end

function Arg.get(name)
	for _,ar in pairs(Arg.arguments) do
		local value = Arg.args[name]
		if ar.long==name then
			if ar.type == "int" then 
				return tonumber(value)
			elseif ar.type == "array" then
				if 0<#value then 
					return value:split(",") 
				else
					return {}
				end
			else
				return value
			end
		else
			if ar.command==name then
				return value
			end
		end
	end
	return "unknown"
end

function Arg.extra(com) --global
	if com=='global' then
		print.M("Extra","Globals")
		for k,v in pairs(_G) do print.I(k,v) end
		--print.M("debug")
		--for k,v in pairs(_G.debug) do print.I(k,v) end
		--print.M("bit32")
		--for k,v in pairs(_G.bit32) do print.I(k,v) end
	end
	
end

if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
	Arg.program({description="" ,epilog=""})
	Arg.add_argument('-d','--debug',{default='error', choices={'error','warning','info','debug'},help='Log level'})
	Arg.add_argument('-n','--new',{action="store_true",help='Give unknown devices'})
	Arg.add_argument('-i','--incomplete',{action="store_true",help='Give incomplete devices'})
	Arg.add_argument('-c','--correct',{action="store_true",help='Give correct devices'})
	Arg.add_argument('-s','--store',{action="store_true",help='Give store devices'})
	Arg.add_argument('-m','--mqtt',{action="store_true",help='Activate and send via MQTT'})
	Arg.add_argument('-t','--time',{default=10,type="int",help='Collection time (s) default: 10'})
	Arg.add_argument('-f','--output',{default="",type="string",help='Output scan to file (default stdio)'})
	Arg.add_argument('-l','--lan',{default="",type="array",help='languages comma seperated (nl,en,fr)'})

	print(Arg.help())
	Arg.parse(arg)
	for k,v in pairs(Arg.args) do print(k,v) end
	
	--print(Arg.get('new'))
	--print(Arg.get('time'))
	--print(Arg.get('something'))
	--print (ar['h'])
	print(Arg.get('lan'))
else
	return Arg
end
