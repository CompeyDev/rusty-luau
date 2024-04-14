local task = require("@lune/task")

local mod = require("../mod")
local Signal = mod.signal
type Signal<T...> = mod.Signal<T...>

local option = require("option")
type Option<T> = option.Option<T>
local Some = option.Some
local None = option.None

local Future = {}
export type Status = "initialized" | "running" | "cancelled" | "done"
export type Future<T> = typeof(Future) & {
	_fn: (set: (value: T) -> ()) -> T,
	_ret: T?,
	_thread: thread,
	_spawnEvt: Signal<()>,
	_retEvt: Signal<T, Status>,
	_status: Status,
}

function Future.new<T>(fn: (...any) -> T, args: { any })
	return setmetatable(
		{
			_thread = coroutine.create(function(spawnEvt: Signal<()>, retEvt: Signal<T, Status>)
				spawnEvt:Fire()

				local ret = fn(table.unpack(args))
				retEvt:Fire(ret, "done")
			end),

			_spawnEvt = Signal.new(),
			_retEvt = Signal.new(),
			_status = "initialized",
		} :: Future<T>,
		{
			__index = Future,
		}
	)
end

function Future.poll<T>(self: Future<T>): (Status, Option<T>)
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

	local retOpt = if self._ret == nil then None() else Some(self._ret)
	return self._status, retOpt
end

function Future.cancel<T>(self: Future<T>)
	self._retEvt:Fire(nil :: any, "cancelled")
	self._status = "cancelled"
end
