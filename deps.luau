-- All types from https://github.com/ffrostflame/LuauSignal/blob/f8305cc6b/src/init.luau#L97-L110

return function(isRoblox: boolean, isLune: boolean)
	local SIGNAL_PATH = "Packages/_Index/ffrostflame_luausignal@0.2.4/luausignal/src/init.luau"
	local signal = if isRoblox
		then require(script.Parent.Parent.luausignal :: ModuleScript)
		elseif isLune then require("@lune/luau").load(
			'local task = require("@lune/task")\n' .. require("@lune/fs").readFile(SIGNAL_PATH)
		)()
		else error("Unsupported runtime: " .. _VERSION)

	local task = if isRoblox
		then task
		elseif isLune then require("@lune/task")
		else error("Unsupported runtime: " .. _VERSION)

	return {
		signal = signal,
		task = task,
	}
end
