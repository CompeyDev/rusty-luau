local tableEq = require("util").tableEq

--[=[
	@class Result

	Error handling with the [Result] type.

	[Result]`<T, E>` is the type used for returning a possible error. It is a class with the 
	constructor variants, [Result:Ok]`(T)`, representing success and containing a value, and 
	[Result:Err]`(E)`, representing error and containing an error value.

	```lua
	local result: Result<number, string>

	-- Both variants `Ok` and `Err` fit into the type
	result = Ok(21)
	result = Err("some error")
	```

	Functions return [Result] whenever errors are expected and recoverable.

	A simple function returning [Result] might be defined and used like so:
	```lua
	local PAT = "v(%d+)"

	function parseVersion(str: string): Result<number, string>
		local version: number = string.match(str, PAT)

		if version == 0 then
			return Err("Version cannot be zero")
		else if version == nil then
			return Err("Invalid string")
		end

		return Ok(version)
	end

	print("Successful result: " .. parseVersion("v12"):display())
	print("Error result: " .. parseVersion("vString"):display())
	```

	[Result] comes with some convenience methods that make working with it more succinct.

	```lua
	local goodResult: Result<number, number> = Ok(10)
	local badResult: Result<number, number> = Err(10)

	-- The `isOk`and `isErr` methods do what they say.
	assert(goodResult:isOk() and not goodResult:isErr())
	assert(badResult:isErr() and not badResult:isOk())

	-- `map` produces a new result from an existing one 
	goodResult = goodResult:map(function(i) return i + 1 end)
	badResult = badResult:map(function(i) return i - 1 end)

	-- Use `and_then` to continue the computation.
	local anotherGoodResult: Result<boolean, number> = goodResult:andThen(function(i) return Ok(i == 11) end)
	
	-- Use `or_else` to handle the error
	local badResult: Result<number, number> = bad_result:orElse(function(i) return Ok(i + 20) end)

	-- Get the internal `Ok` value and panic if there is an `Err`
	local finalAwesomeResult: boolean = anotherGoodResult:unwrap()
	```
]=]
local Result = {}

export type Result<T, E> = typeof(Result) & {
    _value: T,
    _error: E,
    typeId: "Result",
}

--[=[
	@within Result

	Contains the success value.

	@param val T
	@return Result<T, E>
]=]
function Ok<T, E>(val: T): Result<T, E>
    return Result.new(val, (nil :: unknown) :: E)
end

--[=[
	@within Result

	Contains the error value.

	@param err E
	@return Result<T, E>
]=]
function Err<T, E>(err: E): Result<T, E>
    return Result.new((nil :: unknown) :: T, err)
end

--[=[
	@within Result
	@private

	Constructs a [Result]. **For internal use only**.

	For user consumption, see [Result:Ok] and [Result:Err].

	@param err E
	@return Result<T, E>
]=]
function Result.new<T, E>(val: T, err: E)
    return setmetatable(
        {
            _value = val,
            _error = err,
            typeId = "Result",
        } :: Result<T, E>,
        {
            __index = Result,
            __tostring = function<T, E>(self: Result<T, E>)
                if self:isOk() then
                    return `{self.typeId}::Ok({self._value})`
                end

                if self:isErr() then
                    return `{self.typeId}::Err({self._error})`
                end

                return `{self.typeId}<T, E>`
            end,
            __eq = function<T, E>(self: Result<T, E>, other: Result<T, E>)
                if
                    typeof(self._value) ~= "table"
                    and typeof(self._error) ~= "table"
                    and typeof(other._value) ~= "table"
                    and typeof(other._error) ~= "table"
                then
                    return self._value == other._value
                        and self._error == other._error
                end

                return tableEq(self._value, other._value)
                    and tableEq(self._error, other._error)
            end,

            -- TODO: Implement equality and arithmetic metamethods
            -- TODO: Implement __iter, once iterators traits exist
        }
    )
end

--[=[
	@within Result

	Returns `true` if the result is [Result:Ok].

	```lua
	local x: Result<number, string> = Ok(3)
	assert(x:isOk())

	x = Err("Some error message")
	assert(not x:isOk())
	```

	@param self Result<T, E>
	@return boolean
]=]
function Result.isOk<T, E>(self: Result<T, E>): boolean
    if self._value == nil then
        return false
    end

    return true
end

--[=[
	@within Result

	Returns `true` if the result is [Result:Ok] and the value inside it matches a 
	predicate.

	```lua
	local x: Result<number, string> = Ok(2)
	assert(x:isOkAnd(function(x) return x > 1 end))

	x = Ok(0)
	assert(not x:isOkAnd(function(x) return x > 1 end))

	x = Err("hey")
	assert(not x:isOkAnd(function(x) return x > 1 end))
	```

	@param self Result<T, E>
	@param predicate (val: T?) -> boolean
	@return boolean
]=]
function Result.isOkAnd<T, E>(
    self: Result<T, E>,
    predicate: (val: T?) -> boolean
): boolean
    return self:isOk() and predicate(self._value)
end

--[=[
	@within Result

	Returns `true` if the result is [Result:Err].

	```lua
	local x: Result<number, string> = Ok(3)
	assert(not x:isErr())

	x = Err("Some error message")
	assert(x:isErr())
	```

	@param self Result<T, E>
	@return boolean
]=]
function Result.isErr<T, E>(self: Result<T, E>)
    return not self:isOk()
end

--[=[
	@within Result

	Returns `true` if the result is [Result:Err] and the value inside it matches a 
	predicate.

	```lua
	local x: Result<number, string> = Ok(2)
	assert(not x:isErrAnd(function(x) return x > 1 end))

	x = Err(3)
	assert(x:isErrAnd(function(x) return x > 1 end))

	x = Err("hey")
	assert(not x:isErrAnd(function(x) return x > 1 end))
	```

	@param self Result<T, E>
	@param predicate (val: T?) -> boolean
	@return boolean
]=]
function Result.isErrAnd<T, E>(
    self: Result<T, E>,
    predicate: (val: E) -> boolean
): boolean
    if self:isErr() then
        return predicate(self._error)
    end

    return false
end

--[=[
	@within Result

	Maps a [Result]<T, E> to [Result]<U, E> by applying a function to a contained [Result:Ok] value, 
	leaving an [Result:Err] value untouched.

	This function can be used to compose the results of two functions.

	```lua
	local lines = "1\n2\n3\n4\n"

	function parseInt(x: string): Result<number, string>
		local num = tonumber(x)

		if num == nil then
			return Err("not an integer")
		end

		return Ok(num)
	end

	for line in lines:split("\n") do
		local number = parseInt(line)

		if number:isOk() then
			print(number:unwrap())
		else
			print("not a number!")
		end
	end
	```

	@param self Result<T, E>
	@param op (val: T) -> U
	@return Result<U, E>
]=]
function Result.map<T, E, U>(self: Result<T, E>, op: (val: T) -> U): Result<U, E>
    if self:isOk() then
        return Result.new(op(self._value), self._error) :: Result<U, E>
    end

    return Err(self._error)
end

--[=[
	@within Result

	Returns the provided default (if [Result:Err]), or applies a function to 
	the contained value (if [Result:Ok]).

	Arguments passed to [Result:mapOr] are eagerly evaluated; if you are passing the 
	result of a function call, it is recommended to use [Result:mapOrElse], which is 
	lazily evaluated.

	```lua
	local x: Result<string, string> = Ok("foo")
	assert(x:mapOr("bar", string.upper) == "FOO")

	x = Err("foo")
	assert(x:mapOr("bar", string.upper) == "bar")
	```

	@param self Result<T, E>
	@param default U
	@param op (val: T) -> U
	@return U
]=]
function Result.mapOr<T, E, U>(self: Result<T, E>, default: U, op: (val: T) -> U): U
    if self:isOk() then
        return op(self._value)
    end

    return default
end

--[=[
	@within Result

	Maps a [Result]<T, E> to U by applying fallback function default to a contained
	[Result:Err] value, or function f to a contained [Result:Ok] value.

	This function can be used to unpack a successful result while handling an error.

	```lua
	local x: Result<string, string> = Ok("foo")
	assert(x:mapOrElse(function(x) return "error: ".. x end, string.upper) == "FOO")

	x = Err("foo")
	assert(x:mapOrElse(function(x) return "error: ".. x end, string.upper) == "error: foo")
	```

	@param self Result<T, E>
	@param default (val: E) -> U
	@param op (val: T) -> U
	@return U
]=]
function Result.mapOrElse<T, E, U>(
    self: Result<T, E>,
    default: (val: E) -> U,
    op: (val: T) -> U
): U
    if self:isOk() then
        return op(self._value)
    end

    return default(self._error)
end

--[=[
	@within Result

	Maps a [Result]<T, E> to [Result]<T, F> by applying a function to a contained 
	[Result:Err] value, leaving an [Result:Ok] value untouched.

	This function can be used to pass through a successful result while handling an
	error.

	```lua
	local function stringify(x: number): string
		return string.format("error code: %d", x)
	end

	local x: Result<number, number> = Ok(2)
	assert(x:mapErr(stringify) == Ok(2))

	x = Err(13)
	assert(x:mapErr(stringify) == Err("error code: 13"))
	```

	@param self Result<T, E>
	@param op (val: E) -> F
	@return Result<T, F>
]=]
function Result.mapErr<T, E, F>(self: Result<T, E>, op: (val: E) -> F): Result<T, F>
    if self:isErr() then
        return Result.new(self._value, op(self._error))
    end

    return Ok(self._value)
end

--[=[
	@within Result

	Calls the provided closure with a reference to the contained value 
	(if [Result:Ok]).

	```lua
	function parseInt(x: string): Result<number, string>
		local num = tonumber(x)

		if num == nil then
			return Err("not an integer")
		end

		return Ok(num)
	end

	local x = parseInt("4")
		:inspect(function(x) print("original: " .. x) end)
		:map(function(x) return x ^ 3 end)
		:expect("not an integer")

	```

	@param self Result<T, E>
	@param op (val: E) -> ()
	@return Result<T, E>
]=]
function Result.inspect<T, E>(self: Result<T, E>, op: (val: T) -> ()): Result<T, E>
    if self:isOk() then
        op(self._value)
    end

    return self
end

--[=[
	@within Result

	Calls the provided closure with a reference to the contained value 
	(if [Result:Err]).

	```lua
	function parseInt(x: string): Result<number, string>
		local num = tonumber(x)

		if num == nil then
			return Err("not an integer")
		end

		return Ok(num)
	end

	local x = parseInt("string")
		:inspectErr(function(x) print("error: " .. x) end)
		:map(function(x) return x ^ 3 end)
		:unwrap()

	```

	@param self Result<T, E>
	@param op (val: E) -> ()
	@return Result<T, E>
]=]
function Result.inspectErr<T, E>(self: Result<T, E>, op: (val: E) -> ()): Result<T, E>
    if self:isErr() then
        op(self._error)
    end

    return self
end

-- TODO: Iterator traits
-- selene: allow(unused_variable)
function Result.iter<T, E>(self: Result<T, E>): never
    return error("Unimplemented: `Result:iter()`")
end

--[=[
	@within Result

	Returns the contained [Result:Ok] value, consuming the self value.

	Because this function may panic, its use is generally discouraged. Instead, 
	prefer to use [Result:isErr] and handle the Err case explicitly, or call 
	[Result:unwrapOr], [Result:unwrapOrElse], or [Result:unwrapOrDefault].
	Panics

	@error panic -- If the value is a [Result:Err], with a panic message including the passed message, and the content of the `Err`.

	```lua
	local x: Result<number, string> = Err("emergency failure")
	x:expect("Testing expect") -- panics with message `Testing expect: emergency failure`
	```

	## Recommended Message Style
	It is recommended that expect messages are used to describe the reason you expect the 
	[Result] should be [Result:Ok].

	```lua
	local process = require("@lune/process")

	local function envVar<T>(var: string): Result<T, string>
		local val = process.env[var]

		if val == nil then
			return Err("environment variable not found")
		end

		Ok(val)
	end

	local path = envVar("IMPORTANT_PATH")
		:expect("env variable `IMPORTANT_PATH` should be set by `wrapper_script.sh`")
	```
	
	**Hint**: If you’re having trouble remembering how to phrase expect error messages remember to focus 
	on the word “should” as in “env variable should be set by blah” or “the given binary should be available 
	and executable by the current user”.

	@param self Result<T, E>
	@param msg string
	@return T | never
]=]
function Result.expect<T, E>(self: Result<T, E>, msg: string): T | never
    if self:isOk() then
        return self._value
    end

    return error(`panic: {msg}; {self._error}`)
end

--[=[
	@within Result

	Returns the [Result:Ok].

	Because this function may panic, its use is generally discouraged. Instead, prefer to use 
	[Result:unwrapOr], [Result:unwrapOrElse], or [Result:unwrapOrDefault].

	@error panic -- Panics if the value is an [Result:Err], with a panic message provided by the [Result:Err]’s value.

	```lua
	local x: Result<number, string> = Ok(2)
	assert(x:unwrap() == 2)

	x = Err("oh no")
	x:unwrap() -- panics with `oh no`
	```

	@param self Result<T, E>
]=]
function Result.unwrap<T, E>(self: Result<T, E>): T | never
    if self:isOk() then
        return self._value
    end

    return error(
        `panic: \`Result:unwrap()\` called on an \`Err\` value: {self._error}`
    )
end

-- TODO: default values for types
-- selene: allow(unused_variable)
function Result.unwrapOrDefault<T, E>(self: Result<T, E>): never
    return error("Unimplemented: `Result:unwrapOrDefault()`")
end

--[=[
	@within Result

	Returns the contained [Result:Err].

	@error panic -- Panics if the value is an [Result:Ok], with a panic message including the passed message, and the content of the [Resul:Ok].

	```lua
	local x: Result<number, string> = Ok(10)
	x:expectErr("Testing expect") -- panics with `Testing expect: 10`
	```

	@param self Result<T, E>
	@param msg string
	@return E | never
]=]
function Result.expectErr<T, E>(self: Result<T, E>, msg: string): E | never
    if self:isErr() then
        return self._error
    end

    return error(`panic: {msg}; {self._error}`)
end

--[=[
	@within Result

	Returns the contained [Result:Err].

	@error panic -- Panics if the value is an [Result:Ok], with a panic message provided by the [Result:Ok]’s value.

	```lua
	local x: Result<number, string> = Ok(2)
	x:unwrapErr() -- panics with `2`
	```
	```lua
	x = Err("oh no")
	assert(x:unwrapErr() == "oh no")
	```

	@param self Result<T, E>
	@return E | never
]=]
function Result.unwrapErr<T, E>(self: Result<T, E>): E | never
    if self:isErr() then
        return self._error
    end

    return error(
        `panic: \`Result:unwrapErr()\` called on an \`Ok\` value: {self._value}`
    )
end

-- TODO: How the fuck do I implement this?
-- selene: allow(unused_variable)
function Result.intoOk<T, E>(self: Result<T, E>): never
    return error("Unimplemented: `Result:intoOk()`")
end
-- selene: allow(unused_variable)
function Result.intoErr<T, E>(self: Result<T, E>): never
    return error("Unimplemented: `Result:intoErr()`")
end

--[=[
	@within Result

	Returns res if the result is [Result:Ok], otherwise returns the 
	[Result:Err] value of self.

	```lua
	local x: Result<number, string> = Ok(2)
	local y: Result<string, string> = Err("late error")
	assert(x:and_(y) == Err("late error"))
	
	local x: Result<number, string> = Err("early error")
	local y: Result<string, string> = Ok("foo")
	assert(x:and_(y) == Err("early error"))
	
	local x: Result<number, string> = Err("not a 2")
	local y: Result<string, string> = Err("late error")
	assert(x:and_(y) == Err("not a 2"))
	
	local x: Result<number, string> = Ok(2)
	local y: Result<string, string> = Ok("different result type")
	assert(x:and_(y) == Ok("different result type"))
	```

	@param self Result<T, E>
	@param res Result<U, E>
	@return Result<U, E>
]=]
function Result.and_<T, E, U>(self: Result<T, E>, res: Result<U, E>): Result<U, E>
    if self:isOk() then
        return res
    end

    return Err(self._error)
end

--[=[
	@within Result

	Calls `op` if the result is [Result:Ok], otherwise returns the 
	[Result:Err] value of `self`.

	This function can be used for control flow based on [Result] 
	values.

	```lua
	function sqThenToString(x): Result<string, string>
		if typeof(sq) ~= "number" then
			return Err("not a number: '" .. x .. "'")
		end

		return Ok(x ^ 2):map(function(sq)
			return tostring(sq)
		end)
	end

	assert(Ok(2):andThen(sqThenToString) == Ok("4"))
	assert(Err("string"):andThen(sqThenToString) == Err("not a number: 'string'"))
	```

	Often used to chain fallible operations that may return [Result:Err].

	@param self Result<T, E>
	@param op (...any) -> any
	@return Result<U, E>
]=]
function Result.andThen<T, E, U>(self: Result<T, E>, op: (...any) -> any): Result<U, E>
    if self:isOk() then
        return op(self._value)
    end

    return Err(self._error) :: Result<U, E>
end

--[=[
	@within Result

	Calls `op` if the result is [Result:Ok], otherwise returns the 
	[Result:Err] value of `self`.

	This function can be used for control flow based on [Result] 
	values.

	```lua
	local x: Result<number, string> = Ok(2)
	local y: Result<number, string> = Err("late error")
	assert(x:or_(y) == Ok(2))
	
	local x: Result<number, string> = Err("early error") 
	local y: Result<number, string> = Ok(2)
	assert(x:or_(y) == Ok(2))
	
	local x: Result<number, string> = Err("not a 2")
	local y: Result<number, string> = Err("late error")
	assert(x:or_(y) == Err("late error"))
	
	local x: Result<number, string> = Ok(2)
	local y: Result<number, string> = Ok(100)
	assert(x:or_(y) == Ok(2))
	```

	@param self Result<T, E>
	@param res Result<T, F>
	@return Result<T, F> | never
]=]
function Result.or_<T, E, F>(self: Result<T, E>, res: Result<T, F>): Result<T, F> | never
    if self:isErr() then
        return res
    end

    if self:isOk() then
        return Ok(self._value) :: Result<T, F>
    end

    return error("called `Result:or()` with an invalid value")
end

--[=[
	@within Result

	Calls `op` if the result is [Result:Ok], otherwise returns the 
	[Result:Err] value of `self`.

	This function can be used for control flow based on [Result] 
	values.

	```lua
	function sq(x: number): Result<number, number>
		return Ok(x * x)
	end

	function err(x: number): Result<number, number>
		return Err(x)
	end

	assert(Ok(2):orElse(sq):orElse(sq) == Ok(2))
	assert(Ok(2):orElse(err):orElse(sq) == Ok(2))
	assert(Err(3):orElse(sq):orElse(err) == Ok(9))
	assert(Err(3):orElse(err):orElse(err) == Err(3))
	```

	@param self Result<T, E>
	@param op (x: E) -> Result<T, U>
	@return Result<T, U>
]=]
function Result.orElse<T, E, U>(
    self: Result<T, E>,
    op: (x: E) -> Result<T, U>
): Result<T, U>
    if self:isErr() then
        return op(self._error)
    end

    return Ok(self._value)
end

--[=[
	@within Result

	Returns the contained [Result:Ok] value or a provided default.

	Arguments passed to [Result:unwrapOr] are eagerly evaluated; if you are passing the 
	result of a function call, it is recommended to use [Result:unwrapOrElse], which is 
	lazily evaluated.

	```lua
	local default = 2
	local x: Result<number, string> = Ok(9)
	assert(x:unwrapOr(default), 9)

	x = Err("error")
	assert(x:unwrapOr(default), default)
	```

	@param self Result<T, E>
	@param default T
	@return T
]=]
function Result.unwrapOr<T, E>(self: Result<T, E>, default: T): T
    if self:isOk() then
        return self._value
    end

    return default
end

--[=[
	@within Result

	Returns the contained [Result:Ok] value or computes it from a closure.

	```lua
	function count(x: string): number
		return #x
	end

	assert(Ok(2):unwrapOrElse(count) == 2))
	assert(Err("foo"):unwrapOrElse(count) == 3))
	```

	@param self Result<T, E>
	@param op (x: E) -> T
	@return T
]=]
function Result.unwrapOrElse<T, E>(self: Result<T, E>, op: (x: E) -> T): T
    if self:isOk() then
        return self._value
    end

    return op(self._error)
end

--[=[
	@within Result

	Returns true if the [Result:Ok] value is `val`.

	```lua
	local x: Result<number, string> = Ok(2)
	assert(x:contains(2))

	x = Ok(3)
	assert(not x:contains(2))

	x = Err(2)
	assert(not x:contains(2))
	```

	@param self Result<T, E>
	@param val T
	@return boolean
]=]
function Result.contains<T, E>(self: Result<T, E>, val: T): boolean
    if self:isOk() then
        return self._value == val
    end

    return false
end

--[=[
	@within Result

	Returns true if the [Result:Err] value is `err`.

	```lua
	local x: Result<number, string> = Err(2)
	assert(x:containsErr(2))

	x = Err(3)
	assert(not x:containsErr(2))

	x = Ok(2)
	assert(not x:containsErr(2))
	```

	@param self Result<T, E>
	@param err E
	@return boolean
]=]
function Result.containsErr<T, E>(self: Result<T, E>, err: E): boolean
    if self:isErr() then
        return self._error == err
    end

    return false
end

--[=[
	@within Result

	Returns a formatted representation of the result, often
	used for printing to stdout.

	```lua
	local x: Result<number, string> = Ok(123)
	local y: Result<number, string> = Err("error")

	print(x:display()) -- prints `Result::Ok(123)`
	print(y:display()) -- prints `Result::Err("error")`
	```

	@param self Result<T, E>
	@return string
]=]
function Result.display<T, E>(self: Result<T, E>): string
    return tostring(self)
end

return {
    Ok = Ok,
    Err = Err,
    Result = Result,
}
