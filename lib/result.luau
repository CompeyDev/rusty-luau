local Result = {}
export type Result<T, E> = typeof(Result) & {
	_value: T,
	_error: E,
	typeId: "Result",
}

function Ok<T, E>(val: T): Result<T, E>
	return Result.new(val, (nil :: unknown) :: E)
end

function Err<T, E>(err: E): Result<T, E>
	return Result.new((nil :: unknown) :: T, err)
end

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
					return self._value == other._value and self._error == other._error
				end

				error(`eq: cannot compare {tostring(self)} and {tostring(other)}`)
			end,

			-- TODO: Implement equality and arithmetic metamethods
			-- TODO: Implement __iter, once iterators traits exist
		}
	)
end

function Result.isOk<T, E>(self: Result<T, E>): boolean
	if self._value == nil then
		return false
	end

	return true
end

function Result.isOkAnd<T, E>(self: Result<T, E>, predicate: (val: T?) -> boolean): boolean
	return self:isOk() and predicate(self._value)
end

function Result.isErr<T, E>(self: Result<T, E>)
	return not self:isOk()
end

function Result.isErrAnd<T, E>(self: Result<T, E>, predicate: (val: E) -> boolean): boolean
	if self:isErr() then
		return predicate(self._error)
	end

	return false
end

function Result.map<T, E, U>(self: Result<T, E>, op: (val: T) -> U): Result<U, E>
	if self:isOk() then
		return Result.new(op(self._value), self._error) :: Result<U, E>
	end

	return Err(self._error)
end

function Result.mapOr<T, E, U>(self: Result<T, E>, default: U, op: (val: T) -> U): U
	if self:isOk() then
		return op(self._value)
	end

	return default
end

function Result.mapOrElse<T, E, U>(self: Result<T, E>, default: (val: E) -> U, op: (val: T) -> U): U
	if self:isOk() then
		return op(self._value)
	end

	return default(self._error)
end

function Result.mapErr<T, E, F>(self: Result<T, E>, op: (val: E) -> F): Result<T, F>
	if self:isErr() then
		return Result.new(self._value, op(self._error))
	end

	return Ok(self._value)
end

function Result.inspect<T, E>(self: Result<T, E>, op: (val: T) -> nil): Result<T, E>
	if self:isOk() then
		op(self._value)
	end

	return self
end

function Result.inspectErr<T, E>(self: Result<T, E>, op: (val: E) -> nil): Result<T, E>
	if self:isErr() then
		op(self._error)
	end

	return self
end

-- TODO: Iterator traits
function Result.iter() end

function Result.expect<T, E>(self: Result<T, E>, msg: string): T | never
	if self:isOk() then
		return self._value
	end

	return error(`panic: {msg}; {self._error}`)
end

function Result.unwrap<T, E>(self: Result<T, E>): T | never
	if self:isOk() then
		return self._value
	end

	return error(`panic: \`Result:unwrap()\` called on an \`Err\` value: {self._error}`)
end

function Result.unwrapOrDefault<T, E>(self: Result<T, E>): never
	return error("TODO: Result:unwrapOrDefault()")
end

function Result.exceptErr<T, E>(self: Result<T, E>, msg: string): E | never
	if self:isErr() then
		return self._error
	end

	return error(`panic: {msg}; {self._error}`)
end

function Result.unwrapErr<T, E>(self: Result<T, E>): E | never
	if self:isErr() then
		return self._error
	end

	return error(`panic: \`Result:unwrapErr()\` called on an \`Ok\` value: {self._value}`)
end

-- TODO: How the fuck do I implement this?
function Result.intoOk<T, E>(self: Result<T, E>) end
function Result.intoErr<T, E>(self: Result<T, E>) end

function Result.and_<T, E, U>(self: Result<T, E>, res: Result<U, E>): Result<U, E>
	if self:isOk() then
		return res
	end

	return Err(self._error)
end

function Result.andThen<T, E, U>(self: Result<T, E>, op: (...any) -> any): Result<U, E>
	if self:isOk() then
		return op(self._value)
	end

	return Err(self._error) :: Result<U, E>
end

function Result.or_<T, E, F>(self: Result<T, E>, res: Result<T, F>): Result<T, F> | never
	if self:isErr() then
		return res
	end

	if self:isOk() then
		return Ok(self._value) :: Result<T, F>
	end

	return error("called `Result:or()` with an invalid value")
end

function Result.orElse<T, E, U>(self: Result<T, E>, op: (x: E) -> Result<T, U>): Result<T, U>
	if self:isErr() then
		return op(self._error)
	end

	return Ok(self._value)
end

function Result.unwrapOr<T, E>(self: Result<T, E>, default: T): T
	if self:isOk() then
		return self._value
	end

	return default
end

function Result.unwrapOrElse<T, E>(self: Result<T, E>, op: (x: E) -> T)
	if self:isOk() then
		return self._value
	end

	return op(self._error)
end

function Result.contains<T, E>(self: Result<T, E>, val: T): boolean
	if self:isOk() then
		return self._value == val
	end

	return false
end

function Result.containsErr<T, E>(self: Result<T, E>, err: E): boolean
	if self:isErr() then
		return self._error == err
	end

	return false
end

return {
	Ok = Ok,
	Err = Err,
	Result = Result,
}
