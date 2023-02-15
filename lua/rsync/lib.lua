local Lib = {}

function Lib.isWin()
	return vim.fn.has'win32'
end

function Lib.getPathSep()
	return Lib.isWin() and '\\' or '/'
end

function Lib.getCurProject()
	return vim.fn.getcwd()
end

function Lib.popMsg(str, t, title, tbl)
	title = title or 'rsync.nvim'
	if vim.notify then
		tbl = tbl or {}
		tbl.title = title
		t = t or vim.log.levels.INFO
		tbl.timeout = 1000
		vim.notify(str, t, tbl)
	else
		print(string.format('[%s]%s: %s', title, t, msg))
	end
end

function Lib.getDirPath(str)
	return str:match("(.*[/\\])")
end

function Lib.getDirName(str)
	return str:match(".*[/\\]([^/\\]+)")
end

function Lib.convertLocalPath(path)
	if not isWin() then return path end
	local disk = path:match("^(%a):\\"):lower()
	local newFp = path:gsub("%a:\\", "/cygdrive/"..disk.."/")
	newFp = newFp:gsub("\\", "/")
	return newFp
end

function Lib.joinStrTbl(tbl, join)
	local s = ""
	local start = true
	join = join or ""
	for _,v in ipairs(tbl) do
		if not start then
			s = s..join
		end
		start = false
		s = s..v
	end
	return s
end

function Lib.joinTbl(a, b)
	local r = {}
	a = a or {}
	b = b or {}
	for k,v in ipairs(a) do
		table.insert(r, a)
	end
	for k,v in ipairs(b) do
		table.insert(r, b)
	end
	return r
end

return Lib
