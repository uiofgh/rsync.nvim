<!-- Finish README -->

# Rsync

Rsync is a simple nvim plugin. It syncs local file to remote location relative to project root whenever the file is saved. This implements the basic idea of remote development. It needs rsync to run, which comes with most Unix-based system. For Windows users, please install cwrsync from website or chocolatey by running 'choco install rsync'.

The code behind this plugin is rather simple, if you have any bugs or suggestions, please submit in issues. If the plugin doesn't suit your needs, you can fork one and modify to your own requirements!

# Usage

Rsync syncs file based on project root.
To config sync options, it reads a config file(DEFAULT: .rsync_config.lua) in project root.

Available options:

Sync file when saved.

```lua
syncOnSave = true
```

Command used to sync file.

```lua
binPath = "C:\\tools\\cwrsync_6.2.4_x64_free\\bin\\rsync"
```

Custom options.

```lua
options = "-rR"
```

When needs extra options, use this option.

```lua
sshArgs = "C:\\tools\\cwrsync_6.2.4_x64_free\\bin\\ssh -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa -p 32200"
```

Remote path to project root.

```lua
remotePath = "user@127.0.0.2:/home/user/code/"
```

Resulting command:

{binPath} {options} {sshArgs} {localPath} {remotePath}{projectName}/{relativePathToProjectRoot}

{localPath} on Windows will be automatically converted to cwrsync format.

Actions can be called from Telescope.

```viml
:Telescope rsync toggleSyncOnSave
:Telescope rsync reloadProjectCfg
```

Or call straight from the plugin's path with lua

```viml
:lua require'rsync'.toggleSyncOnSave
:lua require'rsync'.reloadProjectCfg
```

# Installation

Any plugin manager should do.

Plug

```viml
" Plugin dependencies
Plug 'nvim-lua/plenary.nvim'

Plug 'uiofgh/rsync.nvim'
```

Packer

```lua
use {
	'uiofgh/rsync.nvim',
	requires = {'nvim-lua/plenary.nvim'},
	config = function()
		require'rsync'.setup{
			configName = ".rsync_config.lua",
			defaultProjectCfg = {
				syncOnSave = true,
				binPath = "rsync",
				options = {"-r", "-R"},
				sshArgs = nil,
			},
		}
		local has_telescope, telescope = pcall(require, 'telescope')
		if has_telescope then
			telescope.load_extension'rsync'
		end
	end
}
```
