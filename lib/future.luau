local task = require("@lune/task")

local mod = require("../mod")
local Signal = mod.signal
type Signal<T...> = mod.Signal<T...>

local result = require("result")
local Result = result.Result
export type Result<T, E> = result.Result<T, E>
local Ok = result.Ok
local Err = result.Err

local Future = {}
export type Status = "initialized" | "running" | "cancelled" | "done"
export type Future<T> = typeof(Future) & {
	_fn: (set: (value: T) -> ()) -> T,
	_ret: T,
	_thread: thread,
	_spawnEvt: Signal<()>,
	_retEvt: Signal<T | Result<T, string>, Status>,
	_status: Status,
}

local function _constructor<T>(fn: (Signal<()>, Signal<T, Status>) -> (), args: { any })
	return setmetatable(
		{
			_thread = coroutine.create(fn),

			_spawnEvt = Signal.new(),
			_retEvt = Signal.new(),
			_status = "initialized",
		} :: Future<T>,
		{
			__index = Future,
		}
	)
end

function Future.new<T>(fn: (...any) -> T, args: { any })
	return _constructor(function(spawnEvt: Signal<()>, retEvt: Signal<T, Status>)
		spawnEvt:Fire()

		local ret = fn(table.unpack(args))
		retEvt:Fire(ret, "done")
	end, args)
end

function Future.try<T>(fn: (...any) -> T, args: { any })
	return _constructor(function(spawnEvt: Signal<()>, retEvt: Signal<Result<T, string>, Status>)
		spawnEvt:Fire()

		local ok, ret = pcall(fn, table.unpack(args))
		local result: Result<T, string> = if ok then Ok(ret) else Err(ret)
		retEvt:Fire(result, "done")
	end, args)
end

function Future.poll<T>(self: Future<T>): (Status, T)
	if self._status == "initialized" then
		self._retEvt:Connect(function(firedRet, status: Status)
			self._status = status
			self._ret = firedRet

			-- Cleanup
			coroutine.yield(self._thread)
			coroutine.close(self._thread)

			self._spawnEvt:DisconnectAll()
			self._retEvt:DisconnectAll()
		end)

		self._spawnEvt:Connect(function()
			self._status = "running"
		end)

		coroutine.resume(self._thread, self._spawnEvt, self._retEvt)
	end

	if self._status == "running" then
		-- Just wait a bit more for the signal to fire
		task.wait(0.01)
	end

	return self._status, self._ret
end

function Future.cancel<T>(self: Future<T>)
	self._retEvt:Fire(nil :: any, "cancelled")
	self._status = "cancelled"
end

function Future.await<T>(self: Future<T>): T
	while true do
		local status: Status, ret: T = self:poll()

		if status == "done" then
			return ret
		end
	end
end
