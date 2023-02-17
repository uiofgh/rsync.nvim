local Lib = require'rsync.lib'
local async_task = require "rsync.async_task"

local pickers = require'telescope.pickers'
local finders = require'telescope.finders'
local conf = require'telescope.config'.values
local themes = require'telescope.themes'
local actions = require'telescope.actions'

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
	configName = ".rsync_config.lua",
	defaultProjectCfg = DEFAULT_PROJECT_CFG,
}

local Rsync = {
	globalCfg = {},
	projectCfg = {},
}

local function loadProjectCfg(path)
	local cfg = {}
	local fn = path..Lib.getPathSep()..Rsync.globalCfg.configName
	local f,err = loadfile(fn, 't', cfg)
	if not f then
		return
	end
	f()
	for k,v in pairs(Rsync.globalCfg.defaultProjectCfg) do
		if not cfg[k] then
			cfg[k] = v
		end
	end
	Rsync.projectCfg[path] = cfg
	return true
end

local function getProjectCfg()
	local path = Lib.getCurProject()
	if not Rsync.projectCfg[path] then
		loadProjectCfg(path)
	end
	return Rsync.projectCfg[path]
end

function Rsync.reloadProjectCfg()
	local path = Lib.getCurProject()
	Rsync.projectCfg[path] = nil
	local cfg = getProjectCfg()
	if not cfg then return end
	local msgs = {'reload success'}
	for k,v in pairs(cfg) do
		table.insert(msgs, string.format("%s : %s", k, v))
	end
	local msg = Lib.joinStrTbl(msgs, "\n")
	Lib.popMsg(msg)
end

function Rsync.setup(tbl)
	if not tbl then return end
	for k,v in pairs(tbl) do
		Rsync.globalCfg[k] = v
	end
	for k,v in pairs(DEFAULT_GLOBAL_CFG) do
		if not Rsync.globalCfg[k] then
			Rsync.globalCfg[k] = v
		end
	end
end

function Rsync.toggleSyncOnSave(custom_opts)
	local cfg = getProjectCfg()
	if not cfg then return end
	local msg = cfg.syncOnSave and 'off' or 'on'
	cfg.syncOnSave = not cfg.syncOnSave
	Lib.popMsg('sync_on_save '..msg)
end

function Rsync.onFileSave(info)
	local cfg = getProjectCfg()
	if not cfg then return end
	if not cfg.syncOnSave then return end
	local fp = info.file
	Rsync.syncFile(fp)
end

function Rsync.checkValidSyncCfg()
	local cfg = getProjectCfg()
	if not cfg then return end
	if not cfg.remotePath then return nil, "remotePath" end
	return true
end

function Rsync.syncFile(fp)
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
	if cfg.sshArgs then
		table.insert(options, cfg.sshArgs)
	end
	-- /Users/mac/project
	local projectPath = Lib.getCurProject()
	-- Sometimes fp is a fullpath, changed to relativePath
	-- /Users/mac/project/dir/fp -> dir/fp
	local relFp = fp:gsub(projectPath..Lib.getPathSep(), "")
	-- On Windows, F:\project\dir\fp -> /cygdrive/f/project/dir/fp
	local localPath = Lib.convertLocalPath(projectPath).."/"..relFp
	-- dir/fp -> dir/
	local preDir = Lib.getDirPath(relFp) or ""
	-- /Users/mac/project -> project
	local projectName = Lib.getDirName(projectPath)
	-- RemotePath/project/dir/
	local remotePath = cfg.remotePath..projectName.."/"..preDir
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

function Rsync.createSyncTask(cmd, args)
	async_task.start(cmd, args, Rsync.onSyncEnd)
end

function Rsync.onSyncEnd(task)
	local level = INFO
	local output = task.output
	local strs = {}
	for k,v in ipairs(output) do
		table.insert(strs, v.data)
		if v.t == "error" then
			level = ERROR
		end
	end
	if #strs > 0 then
		local str = Lib.joinStrTbl(strs, "\n")
		Lib.popMsg(str, level)
	end
end

return Rsync
