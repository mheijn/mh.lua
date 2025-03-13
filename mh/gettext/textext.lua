local T = {}

local function quotes(s)
	return string.gsub(s,'"(.-)"',"``%1''")
end

local function escape(txt)
	local s=string.gsub(txt,"\\","$\\backslash$")
	s=string.gsub(s,"\n","\\newline\n")

	s=string.gsub(s,"{","$\\{$")
	s=string.gsub(s,"}","$\\}$")

	s=string.gsub(s,"ë","\\\"{e}")
	s=string.gsub(s,"é","\\'{e}")
	s=string.gsub(s,"è","\\`{e}")
	s=string.gsub(s,"ê","\\^{e}")
	s=string.gsub(s,"ï","\\\"{i}")
	s=string.gsub(s,"ü","\\\"{u}")
	--s=string.gsub(s,"","\\{}")

	s=string.gsub(s,'%[',"(")
	s=string.gsub(s,'%]',")")
	s=string.gsub(s,"/","$/$ ")
	s=string.gsub(s,'_',"-")
	--s=string.gsub(s,'%%',"\\")--%% to create a command
	s=string.gsub(s,'%$%$',"") -- 2 math sign 
	s=quotes(s)
	return s
end

function T.text(txt)
	local s =escape(txt)
	return s
end


if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
else
 return T
end
