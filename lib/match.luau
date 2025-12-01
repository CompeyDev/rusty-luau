--[=[
	@class Match

	A match expression branches on a pattern. 
	
	Match expressions must be exhaustive, meaning that every possible 
	pattern must be matched, i.e., have an arm handling it. The catch all 
	arm (`_`), which matches any value, can be used to do this.

	Match expressions also ensure that all of the left-sided arms match the 
	same type of the scrutinee expression, and the right-sided arms are all
	of the same type.

	```lua
	local word = match "hello" {
		["hello"] = "hi",
		["bonjour"] = "salut",
		["hola"] = "hola",
		_ = "<unknown>",
	}

	assert(word == "hi")
	```
]=]
local Match = {}

--[=[
	@private
	@interface Arm<L, R>
	@within Match

	Represents an arm (right-side) of a match expression.
	
	@type type L -- The type of the scrutinee expression or the left side of the arm
	@field result R -- The resolved value of the match expression or the right side of the arm

]=]
type Arm<L, R> = R | (L?) -> R

--[=[
	@private
	@interface Arms<T, U>
	@within Match

	Represents a constructed matcher.
	
	@type type T -- The type of the scrutinee expression or the left side of the arm
	@field result U -- The resolved value of the match expression or the right side of the arm

]=]
type Arms<T, U> = ({ [T]: Arm<T, U> }) -> U

--[=[
	@function match
	@within Match

	A match expression branches on a pattern. A match expression has a 
	scrutinee expression (the value to match on) and a list of patterns.

	:::note
	Currently, most traditional pattern matching is not supported, with 
	the exception of the catch all pattern (`_`).
	:::
	
	A common use-case of match is to prevent repetitive `if` statements, when
	checking against various possible values of a variable:

	```lua
	local function getGreetingNumber(greeting: string): number
		return match(greeting) {
		   ["hello, world"] = 1,
		   ["hello, mom"] = 2,
		   _ = function(val)
			   return #val
		   end,
	   }
   end

   assert(getGreetingNumber("hello, world") == 1)
   assert(getGreetingNumber("hello, mom") == 2)
   assert(getGreetingNumber("hello, john") == 11)

   @param value T -- The value to match on
   @return matcher Arms<T, U> -- A matcher function to call with the match arms
   ```
]=]
function Match.match<T, U>(value: T): Arms<T, U>
    local function handleArmType(arm: Arm<T, U>, fnArg: T?): U
        if typeof(arm) == "function" then
            return arm(fnArg)
        end

        return arm :: U
    end

    return function(arms)
        for l, r in arms do
            -- Skip the catch all arm for now, get back to it
            -- when we have finished checking for all other
            -- arms
            if l == "_" then
                continue
            end

            if value == l then
                local ret = handleArmType(r, nil)
                return ret
            end
        end

        -- Since we didn't get any matches, we invoke the catch
        -- all arm, giving it the value we have
        local catchAll = arms["_"]
            or error(
                `Non exhaustive match pattern, arm not satisfied for: {value}`
            )

        return handleArmType(catchAll, value)
    end
end

return Match.match
