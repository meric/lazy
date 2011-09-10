local function class(parent)
  parent = parent or {init=function() end}
  local new = {init=function() end}
  for k, v in pairs(parent) do
    new[k] = v
  end
  new.__super = parent
  new.__index = new
  return setmetatable(new, {__call = function(t , ...) 
    local instance=setmetatable({__class = new}, new);
    new.init(instance, ...)
    return instance
  end})
end

return class