local fs = require("@lune/fs")
local luau = require("@lune/luau")

local SIGNAL_PATH =
    "Packages/_Index/ffrostflame_luausignal@0.2.4/luausignal/src/init.luau"
local _signal = require(SIGNAL_PATH)
export type Signal<T...> = _signal.luauSignal<T...>
local signal: {
    new: <T...>() -> Signal<T...>,
} = luau.load(
    'local task = require("@lune/task")\n' .. fs.readFile(SIGNAL_PATH)
)()

return {
    signal = signal,
}
