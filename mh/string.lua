
if not string.bytes then
function string.bytes(str)
    local bytes = {}
    for i = 1, #str do
        bytes[i] = string.byte(str, i)
    end
    return bytes
end
end

if not string.split then
function string:split(delimiter)
    if not delimiter or delimiter == "" then
        return {self} -- If no delimiter is given, return the whole string
    end
    local result = {}

    for match in (self .. delimiter):gmatch("([^"..delimiter.."]*)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end
end

if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
    gen="2r.4r.5r.6r.8"
    for i,v in ipairs( gen:split("r.") ) do  print(i,v)  end
    gen=" nl,en "
    for i,v in ipairs( gen:split(",") ) do  print(i,v)  end
end
