--[[
    Reference: https://doc.rust-lang.org/std/slice/struct.Iter.html
]]

local option = require("option")
type Option<T> = option.Option<T>
local Some = option.Some
local None = option.None

local result = require("result")
type Result<T, E> = result.Result<T, E>
local Ok = result.Ok
local Err = result.Err

local Iter = {}
type Iter<T> = typeof(Iter) & {
	_inner: { T },
	_rev: { T }?,
	_currentPos: number,
	_length: number,
}

local function revTable(tab: {})
	local tbl = tab

	for i = 1, #tbl // 2, 1 do
		tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
	end

	return tbl
end

function Iter.new<T>(iterable: { T })
	return setmetatable(
		{
			_inner = iterable,
			_currentPos = 0,
			_len = #iterable,
		} :: Iter<T>,
		{
			__index = Iter,
		}
	)
end

function Iter.nextBack<T>(self: Iter<T>): Option<T>
	local elem = table.remove(self._inner, #self._inner)

	if elem == nil then
		return None()
	end

	return Some(elem)
end

function Iter.nthBack<T>(self: Iter<T>, n: number): Option<T>
	local rev = self._rev or revTable(self._inner)
	local elem: T? = rev[n]

	if elem ~= nil then
		return Some(elem)
	end

	return None()
end

-- function Iter.advanceBackBy<T>(self: Iter<T>, n: number): Result<(), number> end

--@canError
function Iter.tryRfold<T, B, R, E>(self: Iter<T>, init: B, f: (B, T) -> Result<R, E>): R
	local accum = init

	local next: Option<T> = self:nextBack()
	while next:isSome() do
		accum = f(accum :: B, next:getInner() :: T):unwrap()
		next = self:nextBack()
	end

	return accum
end

function Iter.rfold<T, B, R>(self: Iter<T>, init: B, f: (B, T) -> R): B
	local accum: B | R = init

	local next: Option<T> = self:nextBack()
	while next:isSome() do
		accum = f(accum :: B, next:getInner() :: T)
		next = self:nextBack()
	end

	return accum :: B
end

function Iter.rfind<T, P>(self: Iter<T>, predicate: (T) -> boolean): Option<T>
	local rev = self._rev or revTable(self._inner)

	for _, val in rev do
		if predicate(val) == true then
			return Some(val)
		end
	end

	return None()
end

function Iter.len<T>(self: Iter<T>): number
	return #self._inner
end

function Iter.next<T>(self: Iter<T>): Option<T>
	local nextIdx = self._currentPos + 1

	if nextIdx > self._length then
		return None()
	end

	self._currentPos = nextIdx
	return Some(self._inner[nextIdx])
end

function Iter.count<T>(self: Iter<T>): number
	local count = self._currentPos

	-- "Consume" self
	self = self.new({})

	return count
end

function Iter.nth<T>(self: Iter<T>, n: number): Option<T>
	local elem: T? = self._inner[n]

	if elem ~= nil then
		return Some(elem)
	end

	return None()
end

function Iter.last<T>(self: Iter<T>): Option<T>
	local val = self._inner[self._length]

	-- "Consume" self
	self = self.new({})

	if val == nil then
		-- Should only occur when iterator is empty
		return None()
	end

	return Some(val)
end

function Iter.fold<T, B>(self: Iter<T>, init: B, f: (B, T) -> B)
	local accum = init

	local next: Option<T> = self:nextBack()
	while next:isSome() do
		accum = f(accum, next:getInner() :: T)
		next = self:nextBack()
	end

	return accum
end

function Iter.forEach<T>(self: Iter<T>, f: (T) -> nil): ()
	for _, v in self._inner do
		f(v)
	end
end

function Iter.all<T>(self: Iter<T>, f: (T) -> boolean): boolean
	for _, v in self._inner do
		local predicate = f

		if predicate(v) == false then
			return false
		end
	end

	return true
end

function Iter.any<T>(self: Iter<T>, f: (T) -> boolean): boolean
	for _, v in self._inner do
		local predicate = f

		if predicate(v) == true then
			return true
		end
	end

	return false
end

function Iter.find<T>(self: Iter<T>, predicate: (T) -> boolean): Option<T>
	local next = self:next()

	while next:isSome() do
		local inner: T = next:getInner()
		if predicate(inner) == true then
			return Some(inner)
		end

		next = self:next()
	end

	return None()
end

-- TODO: findMap after filterMap
function Iter.findMap<T, B>(self: Iter<T>, f: (T) -> Option<B>): Option<B>
	return nil :: any
end

return Iter
