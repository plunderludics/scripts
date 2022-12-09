local lib = {}
function lib.split (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end

function lib.last(arr)
    return arr[#arr]
end

function lib.get_keys(t)
   local keys={}
   for key,_ in pairs(t) do
     table.insert(keys, key)
   end
   return keys
end

return lib