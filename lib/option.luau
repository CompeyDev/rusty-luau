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
	)
end

return {
	-- TODO: Implement Option utility methods
	Option = Option,
	Some = Some,
	None = None,
}
