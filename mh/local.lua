local mylocal = {}

TeX_Babel_rev={
	undefined = {0,'??'},
	english = {1,'en'},
	french= {2,'fr'},
	german= {3,'de'},
	dutch= {4,'nl'},
	italian= {5,'it'},
}

Tex_Babel = {}
for s,v in pairs(TeX_Babel_rev) do
	Tex_Babel[v[1]]={v[2],s}
end

function mylocal.language()
	if not _G.language then
		if tex then
			local name = token.get_macro('languagename')
			--tex.print("In Lua we find babel "..name.."\\newline")
			_G.language = TeX_Babel_rev[name][2]
		else
			local lang = os.getenv("LANG") or "unknown"
			_G.language = lang:match("^(%a+)")
        end
    end
    return _G.language
end

function mylocal.setlanguage(short_lang)
	_G.language = short_lang
end

if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
	print(mylocal.language())
else
    return mylocal
end


