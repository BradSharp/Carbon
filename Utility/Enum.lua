return function (names)
	local enum = {}
	for _, name in ipairs(names) do
		enum[name] = "CoreEnum (" .. name .. ")"
	end
	return enum
end
