--[[
	This exists because if the Option module were to have methods to convert
	to Result, and the Result module were to have methods to convert to Option,
	there would be a cyclic dependency.

	So, if a consumer of this library wants to convert between the two, they
	would rather import this conversion module.
]]

local option = require("option")
local Option = option.Option
export type Option<T> = option.Option<T>
local None = option.None
local Some = option.Some

local result = require("result")
local Result = result.Result
export type Result<T, E> = result.Result<T, E>
local Ok = result.Ok
local Err = result.Err

--[=[
	@within Result

	Converts from [Result]`<T, E>` to [Option]`<T>`.

	Converts `self` into an [Option]`<T>`, and discarding the error, if any.

	```lua
	local x: Result<number, string> = Ok(2)
	assert(x:ok() == Some(2))

	x = Err("Nothing here")
	assert(x:ok() == None())
	```

	@param self Result<T, E>
	@return Option<T>
]=]
function Result.ok<T, E>(self: Result<T, E>): Option<T>
	if self:isOk() then
		if self._value == nil then
			return None()
		end

		return Some(self._value)
	end

	return None()
end

--[=[
	@within Result

	Converts from [Result]`<T, E>` to [Option]`<E>`.

	Converts `self` into an [Option]`<E>`, and discarding the success value, if any.

	```lua
	local x: Result<number, string> = Ok(2)
	assert(x:ok() == Some(2))

	x = Err("Nothing here")
	assert(x:ok() == None())
	```

	@param self Result<T, E>
	@return Option<E>
]=]
function Result.err<T, E>(self: Result<T, E>): Option<E>
	if self:isErr() then
		return Option.new(self._error) :: Option<E>
	end

	return None()
end

--[=[
	@within Result

	Transposes a [Result] of an [Option] into an [Option] of a [Result].

	[Result:Ok]\([Option:None]\) will be mapped to [Option:None]. 
	[Result:Ok]\([Option:Some]`(_)`\) and [Result:Err]\(`_`\) will be mapped to 
	[Option:Some]\([Result:Ok]`(_)`\) and [Option:Some]\([Option:Err]`(_)`\).

	```lua
	type SomeErr = {}
	
	local x: Result<Option<number>, SomeErr> = Ok(Some(2))
	local y: Option<Result<number, SomeErr>> = Some(Ok(2))
	assert(x:transpose() == y)
	```

	@param self Result<Option<T>, E>
	@return Option<Result<T, E>>
]=]
function Result.transpose<T, E>(self: Result<Option<T>, E>): Option<Result<T, E>>
	if self._value == None() then
		return None()
	elseif self:isOkAnd(function(val): boolean
		return val._optValue == nil
	end) then
		return Some(Ok(self._value._optValue))
	elseif self:isErr() then
		return Some(Err(self._error))
	end

	error("`Result` is not transposable")
end

--[=[
	@within Option

	Transforms the [Option]`<T>` into a [Result]`<T, E>`, mapping [Option:Some]`(v)` 
	to [Result:Ok]`(v)` and [Option:None] to [Result:Err]`(err)`.

	Arguments passed to [Option:okOr] are eagerly evaluated; if you are passing the result 
	of a function call, it is recommended to use [Option:okOrElse], which is lazily evaluated.

	```lua
	local x: Option<string> = Some("foo")
	assert(x:okOr(0) == Ok("foo"))

	x = None()
	assert(x:okOr(0) == Err(0))
	```

	@param self Option<T>
	@param err E
	@return Result<T, E>
]=]
function Option.okOr<T, E>(self: Option<T>, err: E): Result<T, E>
	if self:isSome() then
		return Ok(self._optValue)
	end

	return Err(err)
end

--[=[
	@within Option

	Transforms the [Option]`<T>` into a [Result]`<T, E>`, mapping [Option:Some]`(v)` to
	[Result:Ok]`(v)` and [Option:None] to [Result:Err]`(err())`.

	```lua
	local x: Option<string> = Some("foo")
	assert(x:okOrElse(function() return 0 end) == Ok("foo"))

	x = None()
	assert(x:okOrElse(function() return 0 end) == Err(0))
	```

	@param self Option<T>
	@param err () -> E
	@return Result<T, E>
]=]
function Option.okOrElse<T, E>(self: Option<T>, err: () -> E): Result<T, E>
	if self:isSome() then
		return Ok(self._optValue :: T)
	end

	return Err(err())
end

--[=[
	@within Option

	Transposes a [Option] of an [Result] into an [Result] of a [Option].

	[Option:None] will be mapped to [Result:Ok]\([Option:None]\). 
	[Option:Some]\([Result:Ok]`(_)`\) and [Option:Some]\([Result:Err]\(`_`\)\) will 
	be mapped to [Result:Ok]\([Option:Some]`(_)`\) and [Result:Err]`(_)`.

	```lua
	type SomeErr = {}
	
	local x: Result<Option<number>, SomeErr> = Ok(Some(5))
	local y: Option<Result<number, SomeErr>> = Some(Ok(5))
	assert(x == y:transpose())
	```

	@param self Option<Result<T, E>>
	@return Result<Option<T>, E>
]=]
function Option.transpose<T, E>(self: Option<Result<T, E>>): Result<Option<T>, E>
	if self:isSome() then
		local inner = self._optValue
		assert(self.typeId == "Option" and inner.typeId == "Result", "Only an `Option` of a `Result` can be transposed")

		if inner:isOk() then
			return Some(Ok(inner._value))
		elseif inner:isErr() then
			return Some(Err(inner._error))
		end
	end

	return Ok(None())
end

return {
	Ok = Ok,
	Err = Err,
	Result = Result,

	Some = Some,
	None = None,
	Option = Option,
}
