local isRoblox = _VERSION == "Luau"
local isLune = _VERSION:find("Lune") == 1
local deps = if isLune then require(script.Parent.Parent.deps)elseif isRoblox then require(script.Parent.deps) else error("Unsupported Runtime!")
local requires = deps(isRoblox, isLune)

local LuauSignal: {
	new: <T...>() -> Signal<T...>
} = requires.signal

export type Signal<T...> = {
	Fire: (self: Signal<T...>,T...) -> (),
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> () -> (),
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> () -> (),
	DisconnectAll: (self: Signal<T...>) -> ()
}

-- From https://gist.github.com/sapphyrus/fd9aeb871e3ce966cc4b0b969f62f539
local function tableEq(tbl1, tbl2)
	-- if tbl1 == tbl2 then
	-- 	return true
	-- elseif type(tbl1) == "table" and type(tbl2) == "table" then
	-- 	for key1, value1 in pairs(tbl1) do
	-- 		local value2 = tbl2[key1]

	-- 		if value2 == nil then
	-- 			-- avoid the type call for missing keys in tbl2 by directly comparing with nil
	-- 			return false
	-- 		elseif value1 ~= value2 then
	-- 			if type(value1) == "table" and type(value2) == "table" then
	-- 				if not tableEq(value1, value2) then
	-- 					return false
	-- 				end
	-- 			else
	-- 				return false
	-- 			end
	-- 		end
	-- 	end

	-- 	-- check for missing keys in tbl1
	-- 	for key2, _ in pairs(tbl2) do
	-- 		if tbl1[key2] == nil then
	-- 			return false
	-- 		end
	-- 	end

	-- 	return true
	-- end

	-- return false

	return true
end

local RobloxEvent = {}
type RobloxEvent<T...> = Signal<T...> & {
	_inner: BindableEvent
}

function RobloxEvent.new<T...>()
	local instance = Instance.new("BindableEvent")
	instance.Parent = script
	instance.Name = tostring({}):split(" ")[2]

	return setmetatable({
		_inner = instance
	}, {
		__index = RobloxEvent
	})
end

function RobloxEvent.Fire<T...>(self: RobloxEvent<T...>, ...: T...)
	return self._inner:Fire(...)
end

function RobloxEvent.Connect<T...>(self: RobloxEvent<T...>, callback: (T...) -> ())
	local conn = self._inner.Event:Connect(callback)
	
	return {
		DisconnectAll = function<T...>(self: RobloxEvent<T...>)
			conn:Disconnect()
			self._inner:Destroy()
		end
	}
end

function RobloxEvent.Once<T...>(self: RobloxEvent<T...>, callback: (T...) -> ())
	local conn = self._inner.Event:Connect(callback)

	return {
		DisconnectAll = function<T...>(self: RobloxEvent<T...>)
			conn:Disconnect()
			self._inner:Destroy()
		end
	}
end

return {
	tableEq = tableEq,
	Signal = setmetatable({}, {
		__index = if isLune then LuauSignal elseif isRoblox then RobloxEvent else error("Unsupported runtime!"),
	}),
}
