local task = require("@lune/task")

local mod = require("../mod")
local Signal = mod.signal
type Signal<T...> = mod.Signal<T...>

local result = require("result")
type Result<T, E> = result.Result<T, E>
local Ok = result.Ok
local Err = result.Err

local option = require("option")
type Option<T> = option.Option<T>
local None = option.None
local Some = option.Some

--[=[
	@class Future

	A future represents an asynchronous computation.

	A future is a value that might not have finished computing yet. This kind of “asynchronous value” 
	makes it possible for a thread to  continue doing useful work while it waits for the value to 
	become available.

	### The [Future:poll] Method
	The core method of future, poll, attempts to resolve the future into a final value. This method does 
	not block if the value is not ready. Instead, the current task is executed in the background, and
	its progress is reported when polled. When using a future, you generally won’t call poll directly, 
	but instead [Future:await] the value.

	```lua
	local net = require("@lune/net")

	local fut: Future<Result<string, string>> = Future.try(function(url)
		local resp = net.request({
			url = url,
			method = "GET",
		})

		assert(resp.ok)

		return resp.body
	end, { "https://jsonplaceholder.typicode.com/posts/1" })

	local resp: Result<string, string> = fut:await()
	print(net.jsonDecode(resp:unwrap()))
	```
]=]
local Future = {}

--[=[
	@private
	@type Status "initialized" | "pending" | "cancelled" | "ready"
	@within Future

	Represents the status of a [Future].
]=]
export type Status = "initialized" | "pending" | "cancelled" | "ready"

--[=[
	@private
	@interface Future<T>
	@within Future

	Represents the internal state of a [Future].
	
	@field _thread thread -- The background coroutine spawned for execution 
	@field _ret T -- The value returned once execution has halted
	@field _spawnEvt Signal<()> -- Event for internal communication among threads pre execution
	@field _retEvt Signal<T | Result<T, string>, Status> -- Event for internal communication among threads post execution
	@field _status Status -- The status of the Future

]=]
export type Future<T> = typeof(Future) & {
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

--[=[
	@within Future

	Constructs a [Future] from a function to be run asynchronously. 

	:::caution
	If a the provided function has the possibility to throw an error, instead of any 
	other rusty-luau types like [Result] or [Option], use [Future:try] instead.
	:::

	@param fn -- The function to be executed asynchronously
	@param args -- The arguments table to be passed to to the function
	@return Future<T> -- The constructed future
]=]
function Future.new<T>(fn: (...any) -> T, args: { any })
	return _constructor(function(spawnEvt: Signal<()>, retEvt: Signal<T, Status>)
		spawnEvt:Fire()

		local ret = fn(table.unpack(args))
		retEvt:Fire(ret, "ready")
	end, args)
end

--[=[
	@within Future

	Constructs a fallible [Future] from a function to be run asynchronously. 

	@param fn -- The fallible function to be executed asynchronously
	@param args -- The arguments table to be passed to to the function
	@return Future<Result<T>> -- The constructed future
]=]
function Future.try<T>(fn: (...any) -> T, args: { any })
	return _constructor(function(spawnEvt: Signal<()>, retEvt: Signal<Result<T, string>, Status>)
		spawnEvt:Fire()

		local ok, ret = pcall(fn, table.unpack(args))
		local result: Result<T, string> = if ok then Ok(ret) else Err(ret)
		retEvt:Fire(result, "ready")
	end, args)
end

--[=[
	@within Future

	Polls a [Future] to completion. 

	@param self Future<T> 
	@return (Status, Option<T>) -- Returns the [Status] and an optional return if completed
]=]
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
			self._status = "pending"
		end)

		coroutine.resume(self._thread, self._spawnEvt, self._retEvt)
	end

	if self._status == "pending" then
		-- Just wait a bit more for the signal to fire
		task.wait(0.01)
	end

	local retOpt = if self._ret == nil then None() else Some(self._ret)
	return self._status, retOpt
end

--[=[
	@within Future

	Cancels a [Future]. 

	@param self Future<T>
]=]
function Future.cancel<T>(self: Future<T>)
	self._retEvt:Fire(nil :: any, "cancelled")
	self._status = "cancelled"
end

--[=[
	@within Future

	Suspend execution until the result of a [Future] is ready. 
	This method continuosly polls a [Future] until it reaches completion. 

	@param self Future<T> 
	@return T -- The value returned by the function on completion
]=]
function Future.await<T>(self: Future<T>): T
	while true do
		local status: Status, ret: Option<T> = self:poll()

		if status == "ready" then
			-- Safe to unwrap, we know it must not be nil
			return ret:unwrap()
		end
	end
end

return Future
