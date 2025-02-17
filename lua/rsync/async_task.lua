local Job = require "plenary.job"

local AllTasks = {}

local M = {}
local _uid = 0

function GenUid()
	if _uid > 10000 then _uid = 0 end
	_uid = _uid + 1
	return _uid
end

function M.start(cmd, args, endCb)
	local uid = GenUid()
	args.verbatim = true
	local job = Job:new {
		command = cmd,
		args = args,
		on_exit = function(j, return_val)
			local task = AllTasks[uid]
			if not task then return end
			task.retcode = return_val
			task.retdata = j:result()
			if task.endCb then task:endCb() end
			AllTasks[uid] = nil
		end,
		on_stdout = function(out, data)
			if not out then return end
			local task = AllTasks[uid]
			if not task then return end
			table.insert(task.output, { t = "info", data = data })
		end,
		on_stderr = function(err, data)
			if not err then return end
			local task = AllTasks[uid]
			if not task then return end
			table.insert(task.output, { t = "error", data = data })
		end,
	}
	AllTasks[uid] = {
		job = job,
		output = {},
		retcode = nil,
		retdata = {},
		endCb = endCb,
	}
	job:start() -- or start()
end

return M
