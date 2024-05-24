local tableEq = require(script.Parent:WaitForChild('util')).tableEq

--[=[
	@class Option

	Type [Option] represents an optional value: every [Option] is either [Option:Some] 
	and contains a value, or [Option:None], and does not. Common uses of an [Option]
	may involve:

	* Initial values
	* Return values for functions that are not defined over their entire input range (partial functions)
	* Return value for otherwise reporting simple errors, where None is returned on error
	* Optional object fields
	* Values that can be loaned or “taken”
	* Optional function arguments

	```lua
	function divide(numerator: number, denominator: number): Option<number>
		if denominator == 0 then
			None()
		else
			return Some(numerator / denominator)
		end
	end
	```
]=]
local Option = {}

export type Option<T> = typeof(Option) & {
	_optValue: T?,
	typeId: "Option"
}

--[=[
	@within Option

	No value.
]=]
function None<T>(): Option<T>
	return Option.new(nil) :: Option<T>
end

--[=[
	@within Option

	Some value of type `T`.
]=]
function Some<T>(val: T): Option<T>
	return Option.new(val) :: Option<T>
end

--[=[
	@within Option

	Converts a potentially `nil` value into an [Option].

	@param val T? -- The value to convert into an [Option]
	@return Option<T>
]=]
function Option.new<T>(val: T?)
	return setmetatable(
		{
			_optValue = val,
			typeId = "Option",
		} :: Option<T>,
		{
			__index = Option,
			__tostring = function<T>(self: Option<T>)
				if self._optValue == nil then
					return `{self.typeId}::None`
				else
					return `{self.typeId}::Some({self._optValue})`
				end
			end,

			__eq = function<T>(self: Option<T>, other: Option<T>): boolean
				if typeof(self._optValue) == "table" and typeof(other._optValue) == "table" then
					return tableEq(self._optValue, other._optValue)
				else
					return self._optValue == other._optValue
				end
			end,
			__lt = function<T>(self: Option<T>, other: Option<T>): boolean
				if self:isSome() and other:isSome() then
					return (self._optValue :: any) < (other._optValue :: any)
				end

				return false
			end,
			__le = function<T>(self: Option<T>, other: Option<T>): boolean
				if self:isSome() and other:isSome() then
					return (self._optValue :: any) <= (other._optValue :: any)
				end

				return false
			end,
		}

		-- TODO: Implement __iter, once iterators traits exist
	)
end

--[=[
	@within Option

	Returns `true` is the [Option] is an [Option:Some] value.

	@param self Option<T>
	@return boolean
]=]
function Option.isSome<T>(self: Option<T>): boolean
	return self._optValue ~= nil
end

--[=[
	@within Option

	Returns `true` is the [Option] is an [Option:Some] value and the value inside of it 
	matches a predicate.

	@param self Option<T>
	@param op (val: T) -> boolean -- The predicate function
	@return boolean
]=]
function Option.isSomeAnd<T>(self: Option<T>, op: (val: T) -> boolean): boolean
	-- We know that it's not None, so this is fine
	return self:isSome() and op(self._optValue :: T)
end

--[=[
	@within Option

	Returns `true` is the [Option] is an [Option:None] value.

	@param self Option<T>
	@return boolean
]=]
function Option.isNone<T>(self: Option<T>): boolean
	return not self:isSome()
end

--[=[
	@within Option

	Returns the [Option:Some].

	@error panic -- Panics if there is an [Option:None] with a custom panic message provided by `msg`.

	```lua
	local x: Option<string> = Some("value")
	assert(x:expect("fruits are healthy") == "value")
	```

	```lua
	local x: Option<string> = None()
	x:expect("fruits are healthy") -- panics with `fruits are healthy`
	```

	@param self Option<T>
	@param msg string -- The panic message
	@return boolean
]=]
function Option.expect<T>(self: Option<T>, msg: string): T | never
	if self:isSome() then
		return self._optValue :: T
	end

	return error(`panic: {msg}; expected Option to be type Option::Some(T), got Option::None`)
end

--[=[
	@within Option

	Returns the [Option:Some].

	Because this function may panic, its use is generally discouraged. Instead, prefer to use 
	[Option:unwrapOr], [Option:unwrapOrElse], or [Option:unwrapOrDefault].

	@error panic -- Panics if the self value is [Option:None].
	@param self Option<T>
	@return T | never
]=]
function Option.unwrap<T>(self: Option<T>): T | never
	if self:isSome() then
		return self._optValue :: T
	end

	return error("called `Option:unwrap()` on a `None` value")
end

--[=[
	@within Option

	Returns the contained [Option:Some] value or a provided default.

	Arguments passed to unwrap_or are eagerly evaluated; if you are passing the result of 
	a function call, it is recommended to use [Option:unwrapOrElse], which is lazily 
	evaluated.

	```lua
	assert(Some("car"):unwrapOr("bike") == "car")
	assert(None():unwrapOr("bike") == "bike")
	```

	@param self Option<T>
	@param default T -- The default value
	@return T
]=]
function Option.unwrapOr<T>(self: Option<T>, default: T): T
	if self:isSome() then
		return self._optValue :: T
	end

	return default
end

--[=[
	@within Option

	Returns the contained [Option:Some] value or computes it from a function.

	```lua
	local k = 10
	assert(Some(4).unwrapOrElse(function()
		return 2 * k
	end) == 4)
	assert(None().unwrapOrElse(function()
		return 2 * k 
	end) == 20)
	```

	@param self Option<T>
	@param default () -> T -- The function which computes the default value
	@return T
]=]
function Option.unwrapOrElse<T>(self: Option<T>, default: () -> T): T
	if self:isSome() then
		return self._optValue :: T
	end

	return default()
end

--[=[
	@within Option

	Maps an [Option]<T> to [Option]<U> by applying a function to a contained value 
	(if [Option:Some]) or returns [Option:None](if [Option:None]).

	```lua
	local maybeSomeString: Option<string> = Some("Hello, World!")
	
	local maybeSomeLen: Option<number> = maybeSomeString:map(function(s)
		return #s
	end)
	assert(maybeSomeLen == 13)

	local x: Option<string> = None()
	assert(x:map(function(s) 
		return #s
	end) == None())
	```

	@param self Option<T>
	@param op (x: T) -> U? -- The function to apply
	@return Option<U>
]=]
function Option.map<T, U>(self: Option<T>, op: (x: T) -> U?): Option<U>
	if self:isSome() then
		local val = op(self._optValue :: T)

		if val == nil then
			return None()
		end

		return Some(val)
	end

	return None()
end

--[=[
	@within Option

	Calls the provided closure with the contained value (if [Option:Some]).

	```lua
	local v = { 1, 2, 3, 4, 5 }

	-- prints "got: 4"
	local x: Option<number> = Option.new(v[4]):inspect(function(x)
		print("got: " .. x)
	end)

	-- prints nothing
	local x: Option<number> = Option.new(v[5]):inspect(function(x) 
		print("got: " .. x)
	end)
	```

	@param self Option<T>
	@param op (x: T) -> () -- The function to call
	@return Option<T>
]=]
function Option.inspect<T>(self: Option<T>, op: (x: T) -> ()): Option<T>
	if self:isSome() then
		op(self._optValue :: T)
	end

	return self
end

--[=[
	@within Option

	Returns the provided default result (if none), or applies a function to 
	the contained value (if any).

	Arguments passed to [Option:mapOr] are eagerly evaluated; if you are passing the 
	result of a function call, it is recommended to use [Option:mapOrElse], 
	which is lazily evaluated.
	
	```lua
	local x: Option<string> = Some("foo")
	assert(x.mapOr(42, function(v) return #v end) == 3)

	local x: Option<string> = None()
	assert(x.mapOr(42, function(v) return #v end) == 42)
	```
	@param self Option<T>
	@param default U -- The default value
	@param op (val: T) -> U -- The function to apply
	@return Option<T>
]=]
function Option.mapOr<T, U>(self: Option<T>, default: U, op: (val: T) -> U)
	if self:isSome() then
		return op(self._optValue :: T)
	end

	return default
end

--[=[
	@within Option

	Computes a default function result (if none), or applies a different function 
	to the contained value (if any).
	
	```lua
	local k = 21;

	local x: Option<string> = Some("foo")
	assert(
		x:mapOrElse(
			function() return 2 * k end,
			function(v) return #v end
		) == 3
	)

	local x: Option<string> = None()
	assert(
		x:mapOrElse(
			function() return 2 * k end,
			function(v) return #v end
		) == 42
	)
	```

	@param self Option<T>
	@param default () -> U -- The function to compute the default value
	@param op (val: T) -> U -- The function to apply
	@return Option<T>
]=]
function Option.mapOrElse<T, U>(self: Option<T>, default: () -> U, op: (val: T) -> U): U
	if self:isSome() then
		return op(self._optValue :: T)
	end

	return default()
end

-- TODO: Iterator traits
function Option.iter(): never
	return error("Unimplemented: `Option:iter()`")
end

--[=[
	@within Option

	Returns [Option:None] if the option is [Option:None], otherwise returns `optb`.

	Arguments passed to and are eagerly evaluated; if you are passing the result of a 
	function call, it is recommended to use [Option:andThen], which is lazily evaluated.
	
	```lua
	local x: Option<number> = Some(2)
	local y: Option<String> = None()
	assert(x:and_(y) == None())

	local x: Option<number> = None()
	local y: Option<string> = Some("foo")
	assert(x:and_(y) == None())

	local x: Option<number> = Some(2)
	local y: Option<string> = Some("foo")
	assert(x:and_(y) == Some("foo"))

	local x: Option<u32> = None()
	local y: Option<string> = None()
	assert(x:and_(y), None())
	```

	@param self Option<T>
	@param optb Option<U> -- The other option
	@return Option<U>
]=]
function Option.and_<T, U>(self: Option<T>, optb: Option<U>): Option<U>
	if self:isSome() then
		return optb
	end

	return None()
end

--[=[
	@within Option

	Returns [Option:None] if the option is [Option:None], otherwise calls `op` with the wrapped 
	value and returns the result.

	Some languages call this operation flatmap.
	
	```lua
	function sqThenToString(x: number): Option<string>
		return Option.new(x ^ 2):map(function(sq)
			return tostring(sq)
		end)
	end

	assert(Some(2):andThen(sqThenToString) == Some(tostring(4)))
	assert(None():andThen(sqThenToString) == None())
	```

	Often used to chain fallible operations that may return [Option:None].

	```lua
	local arr2d = { { "A0", "A1" }, { "B0", "B1" } }

	local item01: Option<string> = Option.new(arr2d[1]):andThen(function(row)
		return row[2]
	end)
	assert(item01 == Some("A1"))

	local item20: Option<string> = Option.new(arr2d[3]):andThen(function(row)
		return row[0]
	end)
	assert(item20 == None())
	```

	@param self Option<T>
	@param op (val: T) -> Option<U> -- The function to call
	@return Option<U>
]=]
function Option.andThen<T, U>(self: Option<T>, op: (val: T) -> Option<U>): Option<U>
	if self:isSome() then
		return op(self._optValue :: T)
	end

	return None()
end

--[=[
	@within Option

	Returns [Option:None] if the option is [Option:None], otherwise calls `predicate` with 
	the wrapped value and returns:

	* [Option:Some](t) if predicate returns `true` (where `t` is the wrapped value), and
	* [Option:None] if predicate returns `false`.
	
	```lua
	function isEven(n: number): boolean
		return n % 2 == 0
	end

	assert(None():filter(isEven) == None())
	assert(Some(3):filter(isEven) == None())
	assert(Some(4):filter(isEven) == Some(4))
	```

	@param self Option<T>
	@param predicate (val: T) -> boolean -- The predicate function which must match an element 
	@return Option<T>
]=]
function Option.filter<T>(self: Option<T>, predicate: (val: T) -> boolean): Option<T>
	if self:isSome() then
		if predicate(self._optValue :: T) then
			return self
		end
	end

	return None()
end

--[=[
	@within Option

	Returns the option if it contains a value, otherwise returns `optb`.

	Arguments passed to [Option:or_] are eagerly evaluated; if you are passing the result of 
	a function call, it is recommended to use [Option:orElse], which is lazily 
	evaluated.
	
	```lua
	local x: Option<number> = Some(2)
	local y: Option<number> = None()
	assert(x:or_(y) == Some(2))

	local x: Option<number> = None()
	local y: Option<number> = Some(100)
	assert(x:or_(y) == Some(100))

	local x: Option<number> = Some(2)
	local y: Option<number> = Some(100)
	assert(x:or_(y) == Some(2))

	local x: Option<number> = None()
	local y: Option<number> = None()
	assert(x:or_(y), None())
	```

	@param self Option<T>
	@param optb Option<T> -- The other option 
	@return Option<T>
]=]
function Option.or_<T>(self: Option<T>, optb: Option<T>): Option<T>
	if self:isSome() then
		return self
	end

	return optb
end

--[=[
	@within Option

	Returns the option if it contains a value, otherwise calls `op` and returns the result.
	
	```lua
	function nobody(): Option<string>
		return None()
	end
	function vikings(): Option<string>
		return Some("vikings")
	end

	assert(Some("barbarians"):orElse(vikings) == Some("barbarians"))
	assert(None():orElse(vikings) == Some("vikings"))
	assert(None():orElse(nobody) == None())
	```

	@param self Option<T>
	@param op () -> Option<T> -- The function to call 
	@return Option<T>
]=]
function Option.orElse<T>(self: Option<T>, op: () -> Option<T>): Option<T>
	if self:isSome() then
		return self
	end

	return op()
end

--[=[
	@within Option

	Returns [Option:Some] if exactly one of `self`, `optb` is [Option:Some], 
	otherwise returns [Option:None].
	
	```lua
	local x: Option<number> = Some(2)
	local y: Option<number> = None()
	assert(x:xor(y) == Some(2))

	local x: Option<number> = None()
	local y: Option<number> = Some(2)
	assert(x:xor(y) == Some(2))

	local x: Option<number> = Some(2)
	local y: Option<number> = Some(2)
	assert(x:xor(y) == None())

	local x: Option<number> = None()
	local y: Option<number> = None()
	assert(x:xor(y) == None())
	```

	@param self Option<T>
	@param optb Option<T> -- The other option
	@return Option<T>
]=]
function Option.xor<T>(self: Option<T>, optb: Option<T>): Option<T>
	if self:isSome() and optb:isSome() then
		return None()
	end

	if self:isSome() then
		return self
	elseif optb:isSome() then
		return optb
	end

	return None()
end

--[=[
	@within Option

	Inserts value into the option, then returns it.

	If the option already contains a value, the old value is dropped.

	See also [Option:getOrInsert], which doesn’t update the value if the 
	option already contains [Option:Some].
	
	```lua
	local opt: Option<number> = None()
	local val: number = opt:insert(1)
	assert(val == 1)
	assert(opt:unwrap() == 1)

	local val: number = opt:insert(2)
	assert(val == 2)
	```

	@param self Option<T>
	@param val T -- The value to insert
	@return T
]=]
function Option.insert<T>(self: Option<T>, val: T): T
	self._optValue = val
	return self._optValue :: T
end

--[=[
	@within Option

	Inserts value into the option, then returns it.

	If the option already contains a value, the old value is dropped.

	See also [Option:getOrInsert], which doesn’t update the value if the 
	option already contains [Option:Some].
	
	```lua
	local opt: Option<number> = None()
	local val: number = opt:insert(1)
	assert(val == 1)
	assert(opt:unwrap() == 1)

	local val: number = opt:insert(2)
	assert(val == 2)
	```

	@param self Option<T>
	@param val T -- The value to insert
	@return T
]=]
function Option.getOrInsert<T>(self: Option<T>, val: T): T
	if self:isNone() then
		self._optValue = val
	end

	return self._optValue :: T
end

--[=[
	@within Option

	Takes the value out of the option, leaving an [Option:None] in its place.
	
	```lua
	local x: Option<number> = Some(2)
	local y: Option<number> = x.take()
	assert(x == None())
	assert(y == Some(2))

	local x: Option<number> = None()
	local y: Option<number> = x.take()
	assert(x == None())
	assert(y == None())
	```

	@param self Option<T>
	@return Option<T>
]=]
function Option.take<T>(self: Option<T>): Option<T>
	if self:isSome() then
		local val = self._optValue :: T
		self._optValue = nil
		return Some(val)
	end

	return None()
end

--[=[
	@within Option

	Replaces the actual value in the option by the value given in parameter, returning 
	the old value if present, leaving an [Option:Some] in its place without 
	deinitializing either one.
	
	```lua
	local x: Option<number> = Some(2)
	local old: Option<number> = x:replace(5)
	assert(x == Some(5))
	assert(old == Some(2))

	local x: Option<number> = None()
	local old: Option<number> = x:replace(3)
	assert(x == Some(3))
	assert(old == None())
	```

	@param self Option<T>
	@param val T
	@return Option<T>
]=]
function Option.replace<T>(self: Option<T>, val: T): Option<T>
	local current: Option<T> = self
	self._optValue = val

	if current:isNone() then
		return current
	end

	return Some(current._optValue :: T)
end

--[=[
	@within Option

	Returns true if `val` is contained in the [Option:Some].
	
	```lua
	local x: Option<number> = Some(2)
	local y: Option<number> = None()

	assert(x:contains(2))
	assert(x:contains(4))
	assert(not y:contains(2))
	```

	@param self Option<T>
	@param val T
	@return boolean
]=]
function Option.contains<T>(self: Option<T>, val: T): boolean
	if self:isSome() then
		return self._optValue == val
	end

	return false
end

--[=[
	@within Option

	Zips `self` with another [Option].
	
	If `self` is [Option:Some](s) and other is [Option:Some](o), this method returns 
	[Option:Some]({s, o}). Otherwise, [Option:None] is returned.

	```lua
	local x: Option<number> = Some(1)
	local y: Option<string> = Some("hi")
	local z: Option<number> = None()

	assert(x:zip(y) == Some({ 1, "hi" }))
	assert(x:zip(z) == None())
	```

	@param self Option<T>
	@param other Option>U>
	@return Option<{T | U}>
]=]
function Option.zip<T, U>(self: Option<T>, other: Option<U>): Option<{ T | U }>
	if self:isSome() and other:isSome() then
		return Some({ self._optValue, other._optValue })
	end

	return None()
end

--[=[
	@within Option

	Zips `self` and another [Option] with function `op`.
	
	If `self` is [Option:Some](s) and other is [Option:Some](o), this method returns 
	[Option:Some](op(s, o)). Otherwise, [Option:None] is returned.

	```lua
	type Point = {
		x: number,
		y: number,
	}
	local Point: Point & {
		new: (x: number, y: number) -> Point,
	} = {}

	function Point.new(x: number, y: number): Point
		return {
			x = x,
			y = y,
		}
	end

	local xCoord: Option<number> = Some(17.5)
	local yCoord: Option<number> = Some(42.7)

	assert(xCoord:zipWith(yCoord, Point.new), Some({ x = 17.5, y = 42.7 }))
	assert(x:zipWith(None(), Point.new), None())
	```

	@param self Option<T>
	@param other Option>U>
	@param op (x: T, y: U) -> R?
	@return Option<R>
]=]
function Option.zipWith<T, U, R>(self: Option<T>, other: Option<U>, op: (x: T, y: U) -> R?): Option<R>
	if self:isSome() and other:isSome() then
		local computed = op(self._optValue :: T, other._optValue :: U)

		if computed ~= nil then
			return Some(computed :: R)
		end
	end

	return None()
end

--[=[
	@within Option

	Unzips an option containing a table of two options.
	
	If `self` is `Some({a, b})` this method returns `(Some(a), Some(b))`.
	Otherwise, `(None(), None())` is returned.

	```lua
	local x: Option<{ number | string }> = Some({ 1, "hi" })
	local y: Option<{ number }> = None()

	assert((x:unzip() == Some(1), Some("hi")))
	assert((y:unzip() == None(), None()))
	```

	@param self Option<T>
	@return (Option<A>, Option<B>)
]=]
function Option.unzip<T, A, B>(self: Option<T>): (Option<A>, Option<B>)
	if self:isSome() then
		if self:isSome() and typeof(self._optValue) == "table" and #self._optValue == 2 then
			return Some(self._optValue[1] :: A), Some(self._optValue[2] :: B)
		end
	end

	return None(), None()
end

--[=[
	@within Option

	Returns the inner value wrapped by the [Option].

	```lua
	local x: Option<string> = Some("lol")
	local y: Option<string> = None()

	assert(x:unwrapUnchecked() == "lol")
	assert(y:unwrapUnchecked() == nil)
	```

	@param self Option<T>
	@return T?
]=]
function Option.unwrapUnchecked<T>(self: Option<T>): T?
	return self._optValue
end

--[=[
	@within Option

	Returns a formatted representation of the option, often
	used for printing to stdout.

	```lua
	local x: Option<number> = Some(123)
	local y: Option<number> = None()

	print(x:display()) -- prints `Option::Some(123)`
	print(y:display()) -- prints `Option::None`
	```

	@param self Option<T>
	@return string
]=]
function Option.display<T>(self: Option<T>): string
	return tostring(self)
end

return {
	Option = Option,
	Some = Some,
	None = None,
}
