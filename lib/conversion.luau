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

function Result.ok<T, E>(self: Result<T, E>): Option<T>
	if self:isOk() then
		if self._value == nil then
			return None()
		end

		return Some(self._value)
	end

	return None()
end

function Result.err<T, E>(self: Result<T, E>): Option<E>
	if self:isErr() then
		return Option.new(self._error) :: Option<E>
	end

	return None()
end

function Result.transpose<T, E>(self: Result<Option<T>, E>): Option<Result<T, E>>
	-- TODO: Instead of checking whether values are nil, use
	-- utility methods for Options once available
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

function Option.okOr<T, E>(self: Option<T>, err: E): Result<T, E>
	if self:isSome() then
		return Ok(self._optValue)
	end

	return Err(err)
end

function Option.okOrElse<T, E>(self: Option<T>, err: () -> E): Result<T, E>
	if self:isSome() then
		return Ok(self._optValue :: T)
	end

	return Err(err())
end

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
