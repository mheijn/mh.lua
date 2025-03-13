-- Load the individual modules
if not table.deep_merge then
function table.deep_merge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            -- If both t1[k] and t2[k] are tables, recursively merge them
            deep_merge(t1[k], v)
        else
            -- Otherwise, overwrite or add the value
            t1[k] = v
        end
    end
end
end

if not table.copy then
function table.copy(orig)
    local copy = {}
    for key, value in pairs(orig) do
        --print("tablecopy",type(value),key)
        if type(value)=="table" then
            copy[key]= table.copy(value)
        else
            copy[key] = value
        end
    end
    return copy
end
end

if not table.tostring then
function table.tostring(val)
    local s=""
    if type(val)=="table" then
        local j = 1
        for i,v in pairs(val) do
            --print(i,v)
            if #s>0 then s=s..", " end
            if j==i then
                s=s..table.tostring(v)
            else
                s=s..i.."="..table.tostring(v)
            end
            j=j+1
        end
        s = "{"..s.."}"
    else
        s = tostring(val)
    end
    return s
end
end

if not table.merge then
function table.merge(t1, t2)
  -- Merge arrays
    for i = 1, #t2 do
        table.insert(t1, t2[i])
    end
    -- Merge dictionaries
    for k, v in pairs(t2) do
        if type(k) ~= "number" then
            t1[k] = v
        end
    end
    return t1
end
end

function inTable(tab,item)
    for k,v in pairs(tab) do if item==v then return k end end
    return false
end
    
--table.deep_merge.info="table.deep_merge(t1, t2)\nDoes a deep merge from t2 (table) on t1 (table)."
if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
    local a={een="een",twee="twee",drie={een="een",twee="twee"}}
    b=table.copy(a)
    print(table.tostring(a))
    print(table.tostring(b))
    local c={1,2,3,4,5,{11,12,13}}
    local d=table.copy(c)
    print(table.tostring(c))
    print(table.tostring(d))

end

