My Zsh Configuration (.zshrc)

This repository contains my personal .zshrc configuration, designed to be portable, powerful, and easy to use across different Linux distributions. It's built to be smart, automatically adapting its functionality for Arch-based and Fedora-based systems.
✨ Key Features

    Distro-Aware Package Management: Universal aliases (update, install, remove, search) that automatically use the correct package manager (pacman or dnf) depending on your system.

    Interactive Package Search: A single command, fzf_pkgs, to interactively search through your installed packages using fzf, with previews for package details.

    Enhanced Autocompletion: A supercharged completion menu that is case-insensitive, color-coded, and groups suggestions by type for easier navigation.

    Obsidian Sync Utility: A powerful custom function, obsidian_sync [pull|push], to back up and restore your Obsidian vault to a cloud provider using rclone.

    Quality-of-Life Aliases: A collection of useful aliases for common commands like ls, grep, and directory navigation.

    Plugin Ready: Includes a pre-configured section for easily enabling popular plugins like zsh-autosuggestions and zsh-syntax-highlighting.

🚀 Installation

    Place the File:
    Copy this file to your home directory and name it .zshrc.

    cp path/to/this/file ~/.zshrc

    Install Dependencies:
    For all features to work, you'll need to install a few tools.

        On Fedora:

        sudo dnf install fzf rclone zip unzip

        On Arch Linux:

        sudo pacman -S fzf rclone zip unzip

    Start a New Shell:
    Open a new terminal window or run source ~/.zshrc to apply the changes.

🛠️ Usage
Package Management

Forget whether to use pacman or dnf. Just use these simple aliases:

    update: Update all system packages.

    install <package>: Install a new package.

    remove <package>: Remove a package.

    search <keyword>: Search for a package.

Interactive Package Search

To interactively search through all your installed packages, simply run:

fzf_pkgs

This will open an fzf interface where you can type to filter packages. A preview window on the right will show you the details of the selected package.
Obsidian Vault Sync

This function allows you to push and pull backups of your Obsidian vault to a cloud storage provider configured with rclone.

    To back up your local vault to the cloud:

    obsidian_sync push

    This will create a timestamped .zip archive of your vault and upload it.

    To restore the latest backup from the cloud:

    obsidian_sync pull

    This will find the newest backup, download it, and safely extract it, backing up your current local vault first.

🎨 Customization
obsidian_sync Configuration

To adapt the obsidian_sync function for your own setup, you only need to edit the configuration variables at the top of the function in your .zshrc file:

# --- Configuration ---
local readonly vault_name="YourVaultName"
local readonly local_archive_base_dir="$HOME/path/to/your/archives"
local readonly remote_rclone_name="YourRcloneRemoteName"
local readonly remote_archive_path_on_drive="path/on/remote"
# --- End Configuration ---

Recommended Plugins

For an even better experience, install these two popular Zsh plugins using your package manager:

    zsh-autosuggestions

    zsh-syntax-highlighting

After installing them, uncomment the corresponding source lines in the "Suggested Enhancements" section of your .zshrc to enable them.
