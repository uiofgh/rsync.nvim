local Rsync = require "rsync.core"

local augroup = vim.api.nvim_create_augroup("rsync", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "FileWritePost" }, {
	group = augroup,
	callback = Rsync.onFileSave,
})
