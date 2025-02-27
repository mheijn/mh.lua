local Print={}
Print.print = print

local function color_text(c,txt)
    local colors={grey = "\x1b[38;20m",yellow = "\x1b[33;20m",red = "\x1b[31;20m",bold_red = "\x1b[31;1m",
        green = "\x1b[32m", blue = "\x1b[34m",purple = "\x1b[35m",cyan = "\x1b[36m",white = "\x1b[97m",
        reset = "\x1b[0m"}
    return(colors[c]..txt..colors.reset)
end
local function color_tex(c,txt)
    local colors={grey = "\x1b[38;20m",yellow = "\x1b[33;20m",red = "\x1b[31;20m",bold_red = "\x1b[31;1m",
        green = "\x1b[32m", blue = "\x1b[34m",purple = "\\e[35m",cyan = "\\string\\e[36m",white = "\x1b[97m",
        reset = "\\string\\e[0m"}
    return(colors[c]..txt..colors.reset)
end

local function place_message()
    local f
    local info = debug.getinfo(4, "nSl")
    --for k,v in pairs(info) do print(k.."="..v.."\\\\") end
    local filename = string.match(info.short_src, "[^\\/]+$")

    if info.name then f=info.what..":"..info.name else f=info.what end
    return(filename..":"..f.."("..info.currentline..")")
    --return("source")
end

local function glue_args(...)
    local args = {...}
    local txt

    if #args==1 then
        txt = args[1]
    else
        txt = ""
        for i, v in ipairs(args) do
            if type(v)~="string" then v=tostring(v) end
            txt = txt .. string.format("%10s",v)
        end
    end
    return txt
end

local function do_print(t,c,...)
    Print(color_text(c,t.." in "..place_message().." "..glue_args(...)))
end

--local function texconsole(txt)  texio.write_nl(color_tex('cyan',txt)) end
--local function texconsole(txt)  print("\\typeout{"..color_tex('cyan',txt).."}") end
local function texconsole(t,...)
    tex.print("\\Package"..t.."{"..place_message(txt).."}{"..glue_args(...).."}{}")
end

setmetatable(Print, {
    __call = function(_,handle)
        return Print.print(handle)
    end,
})


local sprint = io.write
if tex then
    Print.print = tex.print
    Print.s = function(...) tex.sprint(glue_args(...)) end
    Print.ms = function(...) tex.sprint("$"..glue_args(...).."$") end
    Print.i = function(...) texconsole("Info",...) end
    Print.w = function(...) texconsole("Warning",...) end
    Print.e = function(...) texconsole("Error",...) end
    Print.m = function(...) tex.sprint("$"..glue_args(...).."$") end
else
    Print.s = function(...) io.write(glue_args(...)) end
    Print.ms = function(...) io.write(color_text("cyan",glue_args(...))) end
    Print.i = function(...) do_print("Info","green",...) end
    Print.e = function(...) do_print("Error","red",...) end
    Print.w = function(...) do_print("Warning","blue",...) end
    Print.m = function(...) Print(color_text("cyan",glue_args(...))) end
end

if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
    local s="/home/marc/Nexcloud/tes.lua"
    local filename = string.match(s, "[^\\/]+$")
    print(filename)
    Print("Gewoon")
    Print.s("S print\n")
    Print.i("info")
    Print.e("error")
    Print.w("warning")
else
    return(Print)
end
