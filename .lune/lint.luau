--> Run selene for linting 

local process = require("@lune/process")

local CommandBuilder = require("./util/exec")

process.exit(CommandBuilder.new("selene"):withArg("."):withStdioStrategy("forward"):exec().code)
