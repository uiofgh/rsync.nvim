local Lib = require "rsync.lib"
local async_task = require "rsync.async_task"

local DEBUG = vim.log.levels.DEBUG
local ERROR = vim.log.levels.ERROR
local INFO = vim.log.levels.INFO
local TRACE = vim.log.levels.TRACE
local WARN = vim.log.levels.WARN

local DEFAULT_PROJECT_CFG = {
	syncOnSave = true,
	binPath = "rsync",
	options = "-vr",
	sshArgs = nil,
}

local DEFAULT_GLOBAL_CFG = {
	configName = ".rsync.lua",
	defaultProjectCfg = DEFAULT_PROJECT_CFG,
}

local Rsync = {
	globalCfg = {},
	projectCfg = {},
}

local function loadProjectCfg(path)
	local cfg = {}
	local fn = path .. Lib.getPathSep() .. Rsync.globalCfg.configName
	local f, err = loadfile(fn, "t", cfg)
	if not f then return end
	f()
	Rsync.projectCfg[path] = vim.tbl_deep_extend("keep", cfg, Rsync.globalCfg.defaultProjectCfg)
	return true
end

local function getProjectCfg()
	local path = Lib.getCurProject()
	if not Rsync.projectCfg[path] then loadProjectCfg(path) end
	return Rsync.projectCfg[path]
end

function Rsync.reloadProjectCfg()
	if not Rsync.inited then return end
	local path = Lib.getCurProject()
	Rsync.projectCfg[path] = nil
	local cfg = getProjectCfg()
	if not cfg then return end
	local msgs = { "reload success" }
	for k, v in pairs(cfg) do
		table.insert(msgs, string.format("%s : %s", k, v))
	end
	local msg = table.concat(msgs, "\n")
	Lib.popMsg(msg)
end

function Rsync.setup(tbl)
	Rsync.inited = true
	tbl = tbl or {}
	Rsync.globalCfg = vim.tbl_deep_extend("keep", tbl, DEFAULT_GLOBAL_CFG)
end

function Rsync.toggleSyncOnSave(custom_opts)
	if not Rsync.inited then return end
	local cfg = getProjectCfg()
	if not cfg then return end
	local msg = cfg.syncOnSave and "off" or "on"
	cfg.syncOnSave = not cfg.syncOnSave
	Lib.popMsg("sync_on_save " .. msg)
end

function Rsync.onFileSave(info)
	if not Rsync.inited then return end
	local cfg = getProjectCfg()
	if not cfg then return end
	if not cfg.syncOnSave then return end
	local fp = info.match
	Rsync.syncFile(fp)
end

function Rsync.checkValidSyncCfg()
	local cfg = getProjectCfg()
	if not cfg then return end
	if not cfg.remotePath then return nil, "remotePath" end
	return true
end

function Rsync.syncFile(fp)
	if not Rsync.inited then return end
	local ret, key = Rsync.checkValidSyncCfg()
	if not ret then
		Lib.popMsg(string.format("can't sync, cfg key:%s error", key))
		return
	end
	local cfg = getProjectCfg()
	fp = fp:gsub("\\", "/")
	local binPath = cfg.binPath
	local options = {
		cfg.options,
	}
	if cfg.sshArgs then table.insert(options, cfg.sshArgs) end
	-- /Users/mac/project
	local projectPath = Lib.getCurProject()
	-- On Windows, F:\project\dir\fp -> /cygdrive/f/project/dir/fp
	local localPath = Lib.convertLocalPath(fp)
	local preDir = Lib.relpath(Lib.getDirPath(localPath), projectPath)
	-- /Users/mac/project -> project
	local projectName = cfg.projectName or Lib.getDirName(projectPath)
	-- RemotePath/project/dir/
	local remotePath = cfg.remotePath .. projectName .. "/" .. preDir
	local cmd, args = Rsync.wrapCmd(binPath, options, localPath, remotePath)
	Rsync.createSyncTask(cmd, args)
end

function Rsync.wrapCmd(binPath, options, localPath, remotePath)
	local cmd = binPath or "rsync"
	local args = options or {}
	table.insert(args, localPath)
	table.insert(args, remotePath)
	return cmd, args
end

function Rsync.createSyncTask(cmd, args) async_task.start(cmd, args, Rsync.onSyncEnd) end

function Rsync.onSyncEnd(task)
	local level = INFO
	local output = task.output
	local strs = {}
	for _, v in ipairs(output) do
		table.insert(strs, v.data)
		if v.t == "error" then level = ERROR end
	end
	if #strs > 0 then
		local str = table.concat(strs, "\n")
		Lib.popMsg(str, level)
	end
end

return Rsync
