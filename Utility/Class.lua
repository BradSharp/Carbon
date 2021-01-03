return function (Super)
	
	local Class = {}
	Class.__index = Class
	
	function Class.new()
		return setmetatable({}, Class)
	end
	
	return setmetatable(Class, Super)
	
end
