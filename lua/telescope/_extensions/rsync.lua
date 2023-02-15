local has_telescope, telescope = pcall(require, 'telescope')
local Rsync = require'rsync.core'


if has_telescope then
	return telescope.register_extension {
		setup = Rsync.setup,
		exports = {
			toggle_sync_on_save = Rsync.toggleSyncOnSave,
			reload_project_cfg = Rsync.reloadProjectCfg,
		}
	}
end

