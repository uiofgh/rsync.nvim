local Lib = {}

function Lib.isWin() return vim.fn.has "win32" == 1 end

function Lib.getPathSep() return Lib.isWin() and "\\" or "/" end

function Lib.getCurProject() return vim.fn.getcwd() end

function Lib.popMsg(str, t, title, tbl)
	title = title or "rsync.nvim"
	local ok, notify = pcall(require, "notify")
	if ok then
		tbl = tbl or {}
		tbl.title = title
		t = t or vim.log.levels.INFO
		tbl.timeout = 1000
		vim.schedule(function()
			notify.notify(str, t, tbl)
		end)
	else
		vim.schedule(function()
			print(string.format("[%s]%s: %s", title, t, str))
		end)
	end
end

function Lib.getDirPath(str) return str:match "(.*[/\\])" end

function Lib.getDirName(str) return str:match ".*[/\\]([^/\\]+)" end

function Lib.convertLocalPath(path)
	if not Lib.isWin() then return path end
	local disk = path:match("^(%a):\\"):lower()
	local newFp = path:gsub("%a:\\", "/cygdrive/" .. disk .. "/")
	newFp = newFp:gsub("\\", "/")
	return newFp
end

function Lib.split(s, re, plain, n)
	local i1, ls = 1, {}
	if not re then re = "%s+" end
	if re == "" then return { s } end
	while true do
		local i2, i3 = string.find(s, re, i1, plain)
		if not i2 then
			local last = string.sub(s, i1)
			if last ~= "" then table.insert(ls, last) end
			if #ls == 1 and ls[1] == "" then
				return {}
			else
				return ls
			end
		end
		table.insert(ls, string.sub(s, i1, i2 - 1))
		if n and #ls == n then
			ls[#ls] = string.sub(s, i1)
			return ls
		end
		i1 = i3 + 1
	end
end

function Lib.relpath(P, start)
	local split, min, append = Lib.split, math.min, table.insert
	local sep = Lib.getPathSep()
	start = start or Lib.getCurProject()
	local compare
	if Lib.isWin() then
		P = P:gsub("/", "\\")
		start = start:gsub("/", "\\")
		compare = function(v) return v:lower() end
	else
		compare = function(v) return v end
	end
	local startl, Pl = split(start, sep), split(P, sep)
	local n = min(#startl, #Pl)
	if Lib.isWin() and n > 0 and string.sub(Pl[1], 2, 2) == ":" and Pl[1] ~= startl[1] then return P end
	local k = n + 1 -- default value if this loop doesn't bail out!
	for i = 1, n do
		if compare(startl[i]) ~= compare(Pl[i]) then
			k = i
			break
		end
	end
	local rell = {}
	for i = 1, #startl - k + 1 do
		rell[i] = ".."
	end
	if k <= #Pl then
		for i = k, #Pl do
			append(rell, Pl[i])
		end
	end
	return table.concat(rell, sep)
end

return Lib
