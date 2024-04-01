local Option = {}
export type Option<T> = typeof(Option) & {
	_optValue: T?,
	typeId: "Option",
}

function None<T>(): Option<T>
	return Option.new(nil) :: Option<T>
end

function Some<T>(val: T): Option<T>
	return Option.new(val) :: Option<T>
end

function Option.new<T>(val: T?)
	return setmetatable(
		{
			_optValue = val,
			typeId = "Option",
		} :: Option<T>,
		{
			__index = Option,
			__tostring = function<T>(self: Option<T>)
				-- TODO: Return formatted enum variants too

				if self._optValue == nil then
					return `{self.typeId}::None`
				else
					return `{self.typeId}::Some({self._optValue})`
				end
			end,
		}

		-- TODO: Implement equality and arithmetic metamethods
		-- TODO: Implement __iter, once iterators traits exist
	)
end

function Option.isSome<T>(self: Option<T>): boolean
	return self._optValue ~= nil
end

function Option.isSomeAnd<T>(self: Option<T>, op: (val: T) -> boolean): boolean
	-- We know that it's not None, so this is fine
	return self:isSome() and op(self._optValue :: T)
end

function Option.isNone<T>(self: Option<T>): boolean
	return not self:isSome()
end

function Option.expect<T>(self: Option<T>, msg: string): T | never
	if self:isSome() then
		return self._optValue :: T
	end

	return error(`panic: {msg}; expected Option to be type Option::Some(T), got Option::None`)
end

function Option.unwrap<T>(self: Option<T>): T | never
	if self:isSome() then
		return self._optValue :: T
	end

	return error("called `Option:unwrap()` on a `None` value")
end

function Option.unwrapOr<T>(self: Option<T>, default: T): T
	if self:isSome() then
		return self._optValue :: T
	end

	return default
end

function Option.unwrapOrElse<T>(self: Option<T>, default: () -> T): T
	if self:isSome() then
		return self._optValue :: T
	end

	return default()
end

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

function Option.inspect<T>(self: Option<T>, op: (x: T) -> nil): Option<T>
	if self:isSome() then
		op(self._optValue :: T)
	end

	return self
end

function Option.mapOr<T, U>(self: Option<T>, default: U, op: (val: T) -> U)
	if self:isSome() then
		return op(self._optValue :: T)
	end

	return default
end

function Option.mapOrElse<T, U>(self: Option<T>, default: () -> U, op: (val: T) -> U): U
	if self:isSome() then
		return op(self._optValue :: T)
	end

	return default()
end

-- TODO: Iterator traits
function Option.iter() end

function Option.and_<T, U>(self: Option<T>, optb: Option<U>): Option<U>
	if self:isSome() then
		return optb
	end

	return None()
end

function Option.andThen<T, U>(self: Option<T>, op: (val: T) -> Option<U>): Option<U>
	if self:isSome() then
		return op(self._optValue :: T)
	end

	return None()
end

function Option.filter<T>(self: Option<T>, predicate: (val: T) -> boolean): Option<T>
	if self:isSome() then
		if predicate(self._optValue :: T) then
			return self
		end
	end

	return None()
end

function Option.or_<T>(self: Option<T>, optb: Option<T>): Option<T>
	if self:isSome() then
		return self
	end

	return optb
end

function Option.orElse<T>(self: Option<T>, op: () -> Option<T>): Option<T>
	if self:isSome() then
		return self
	end

	return op()
end

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

function Option.insert<T>(self: Option<T>, val: T): T
	self._optValue = val
	return self._optValue :: T
end

function Option.getOrInsert<T>(self: Option<T>, val: T): T
	if self:isNone() then
		self._optValue = val
	end

	return self._optValue :: T
end

function Option.take<T>(self: Option<T>): Option<T>
	if self:isSome() then
		local val = self._optValue :: T
		self._optValue = nil
		return Some(val)
	end

	return None()
end

function Option.replace<T>(self: Option<T>, val: T): Option<T>
	local current: Option<T> = self
	self._optValue = val

	if current:isNone() then
		return current
	end

	return Some(current._optValue :: T)
end

function Option.contains<T>(self: Option<T>, val: T): boolean
	if self:isSome() then
		return self._optValue == val
	end

	return false
end

function Option.zip<T, U>(self: Option<T>, other: Option<U>): Option<{ T | U }>
	if self:isSome() and other:isSome() then
		return Some({ self._optValue, other._optValue })
	end

	return None()
end

function Option.zipWith<T, U, R>(self: Option<T>, other: Option<U>, op: (x: T, y: U) -> R?): Option<R>
	if self:isSome() and other:isSome() then
		local computed = op(self._optValue :: T, other._optValue :: U)

		if computed ~= nil then
			return Some(computed :: R)
		end
	end

	return None()
end

function Option.unzip<T, A, B>(self: Option<T>): (Option<A>, Option<B>)
	if self:isSome() then
		if self:isSome() and typeof(self._optValue) == "table" and #self._optValue == 2 then
			return Some(self._optValue[1] :: A), Some(self._optValue[2] :: B)
		end
	end

	return None(), None()
end

return {
	Option = Option,
	Some = Some,
	None = None,
}
