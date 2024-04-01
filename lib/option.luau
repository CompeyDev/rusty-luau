local Option = {}
export type Option<T> = typeof(Option) & {
    _optValue: T?,
    typeId: "Option"
}

function None<T>(): Option<T>
    return Option.new(nil) :: Option<T>
end

function Some<T>(val: T): Option<T>
    return Option.new(val) :: Option<T>
end

function Option.new<T>(val: T?)
    return setmetatable({
        _optValue = val,
        typeId = "Option"
    } :: Option<T>, {
        __index = Option,
        __tostring = function(self)
            -- Return formatted enum variants too

            return `{self.typeId}<T>`
        end
    })
end

return {
    -- TODO: Implement Option utility methods
    Option = Option,
    Some = Some,
    None = None
}