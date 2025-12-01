local result = require("../lib/result")
type Result<T, E> = result.Result<T, E>
local Ok = result.Ok
local Err = result.Err

local function canError(): Result<number, string>
	if math.round(math.random()) == 1 then
		return Err("you DIED")
	end

	return Ok(69)
end

function main()
	local val = canError():unwrap()

	print("got value: ", val)
end

return main()
