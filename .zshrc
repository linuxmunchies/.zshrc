#------------------------------------------------------------------------------
# ZSH CONFIGURATION
#------------------------------------------------------------------------------

# Word characters for completion and editing (removes '/' from default)
export WORDCHARS='*?_.~=&;!#$%^(){}<>'

# Shell options
setopt auto_cd          # Automatically cd to a directory if a command is its name
setopt share_history    # Share history between all concurrent shell sessions
setopt hist_ignore_dups # Do not record an event that was just recorded again


# Conditional Check. It ensures the alias is only created if your current terminal is Kitty.
[[ "$TERM" == "xterm-kitty" ]] && alias ssh="TERM=xterm-256color ssh"

# History settings
HISTFILE=~/.zsh_history # Path to the history file
HISTSIZE=20000          # Maximum number of events stored in internal history
SAVEHIST=20000          # Maximum number of events saved to HISTFILE

#------------------------------------------------------------------------------
# KEY BINDINGS
#------------------------------------------------------------------------------
# For a list of key sequences, you can press Ctrl-V then the key combination.
bindkey -e # Use Emacs keybindings

# Navigation
bindkey '^[[H'  beginning-of-line # Home key
bindkey '^[[1~' beginning-of-line # Home key (alternative, e.g., xterm)
bindkey '^[OH'  beginning-of-line # Home key (e.g., VT100)
bindkey '^[[F'  end-of-line       # End key
bindkey '^[[4~' end-of-line       # End key (alternative, e.g., xterm)
bindkey '^[OF'  end-of-line       # End key (e.g., VT100)

# Editing
bindkey '^[[3~' delete-char       # Delete key

# History Navigation (often PageUp/PageDown)
bindkey '^[[5~' up-line-or-history   # PageUp
bindkey '^[[6~' down-line-or-history # PageDown

# Completion/Search based navigation (Arrow keys)
bindkey '^[[A' up-line-or-search    # UpArrow
bindkey '^[[B' down-line-or-search  # DownArrow
bindkey '^[[C' forward-char         # RightArrow
bindkey '^[[D' backward-char        # LeftArrow

#------------------------------------------------------------------------------
# ALIASES, FUNCTIONS, AND ENVIRONMENT
#------------------------------------------------------------------------------

# Environment Variables
export EDITOR=nvim # Preferred text editor

# General Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias zshrc="nvim ~/.zshrc" # Quickly edit this .zshrc file

# Arch Linux Package Management Aliases (uncomment if you use Arch Linux)
# alias pacupdate="sudo pacman -Syu"    # Update all packages
# alias pacinstall="sudo pacman -S"     # Install packages
# alias pacremove="sudo pacman -Rs"     # Remove packages and their dependencies
# alias pacsearch="pacman -Ss"      # Search for packages

# Utility Functions
# take: Create a directory and cd into it
take() {
    mkdir -p "$1" && cd "$1"
}

#------------------------------------------------------------------------------
# PROMPT
#------------------------------------------------------------------------------
# Example: ~/Projects/my-project %
PROMPT='%F{blue}%~%f %# '

#------------------------------------------------------------------------------
# COMPLETION SYSTEM
#------------------------------------------------------------------------------
# Load the Zsh completion system module.
# -U flag prevents alias expansion during function loading.
# -z flag forces zsh-style autoloading (recommended).
autoload -Uz compinit
compinit

# Enable menu-like completion selection
zstyle ':completion:*' menu select

#------------------------------------------------------------------------------
# CUSTOM FUNCTIONS
#------------------------------------------------------------------------------

# fzf_pacman: Interactively search installed Arch Linux packages using fzf
# Requires: fzf, pacman (Arch Linux)
fzf_pacman() {
    # Check for dependencies
    if ! command -v fzf &>/dev/null; then
        print -r -- "Error: fzf is not installed. Please install it to use fzf_pacman."
        return 1
    fi
    if ! command -v pacman &>/dev/null; then
        print -r -- "Error: pacman is not installed. This function is for Arch Linux systems."
        return 1
    fi

    pacman -Qq | fzf \
        --preview="pacman -Qi {1}" \
        --preview-window="right:60%" \
        --height=40% --layout=reverse --border
}


# obsidian_sync: Synchronize Obsidian vault with a remote rclone destination (e.g., ProtonDrive)
# Usage: obsidian_sync [pull|push]
#   pull: Download the most recent vault backup from remote, extract it locally.
#   push: Create a timestamped zip of the local vault, upload it to remote.
# Requires: rclone, zip, unzip
obsidian_sync() {
    local direction="$1"

    # --- Configuration ---
    # Name of your Obsidian vault directory (without paths)
    local readonly vault_name="FoxVault"
    # Local base directory where the vault and its archives are stored
    local readonly local_archive_base_dir="$HOME/ProtonDrive/Archives/Obsidian"
    # Name of your rclone remote (e.g., "ProtonDrive" as configured in `rclone config`)
    local readonly remote_rclone_name="ProtonDrive"
    # Path on the remote where vault archives should be stored (relative to remote's root)
    local readonly remote_archive_path_on_drive="Archives/Obsidian"
    # --- End Configuration ---

    # Derived paths (do not change these directly)
    local readonly local_vault_path="${local_archive_base_dir}/${vault_name}"
    local readonly remote_base_rclone_path="${remote_rclone_name}:${remote_archive_path_on_drive}" # Full rclone remote path (e.g., "ProtonDrive:Archives/Obsidian")

    # Helper function to check for required tools and rclone remote configuration
    _obsidian_sync_check_prerequisites() {
        for tool in rclone zip unzip; do
            if ! command -v "$tool" &>/dev/null; then
                print -r -- "Error: Required tool '${tool}' is not installed. Please install it first."
                return 1
            fi
        done

        if ! rclone listremotes | grep -q "^${remote_rclone_name}:"; then
            print -r -- "Error: rclone remote '${remote_rclone_name}:' is not configured."
            print -r -- "Please run 'rclone config' to set up your '${remote_rclone_name}' remote."
            return 1
        fi
        return 0 # Prerequisites met
    }

    # Perform prerequisite check
    if ! _obsidian_sync_check_prerequisites; then
        return 1
    fi

    # --- PULL LOGIC ---
    if [[ "$direction" == "pull" ]]; then
        print -r -- "Pulling '${vault_name}' from '${remote_rclone_name}'..."

        print -r -- "Finding most recent backup in '${remote_base_rclone_path}'..."
        local latest_backup_filename
        # Get the newest file matching pattern, suppressing rclone errors if path is empty/new
        latest_backup_filename=$(rclone lsf "${remote_base_rclone_path}" --include "${vault_name}_*.zip" 2>/dev/null | sort -r | head -n 1)

        if [[ -z "$latest_backup_filename" ]]; then
            print -r -- "Error: No '${vault_name}_*.zip' backups found in '${remote_base_rclone_path}'."
            return 1
        fi

        local remote_zip_to_download="${remote_base_rclone_path}/${latest_backup_filename}"
        # Download to the local archive base directory
        local local_zip_download_target_dir="${local_archive_base_dir}"
        local local_downloaded_zip_path="${local_zip_download_target_dir}/${latest_backup_filename}"

        print -r -- "Latest backup file: ${latest_backup_filename}"

        # Ensure local download directory exists
        if ! mkdir -p "$local_zip_download_target_dir"; then
            print -r -- "Error: Could not create download directory '${local_zip_download_target_dir}'."
            return 1
        fi

        print -r -- "Downloading '${latest_backup_filename}' from '${remote_rclone_name}'..."
        if ! rclone copy "$remote_zip_to_download" "$local_zip_download_target_dir/" --progress; then
            print -r -- "❌ Failed to download '${latest_backup_filename}'."
            return 1
        fi

        print -r -- "Extracting '${local_downloaded_zip_path}' to '${local_vault_path}'..."

        local backup_dir_path="" # Variable to store path of the local backup
        # Backup existing local vault if it exists
        if [[ -d "$local_vault_path" ]]; then
            backup_dir_path="${local_vault_path}_backup_$(date +%Y%m%d_%H%M%S)"
            print -r -- "Backing up existing local vault to '${backup_dir_path}'..."
            if ! mv "$local_vault_path" "$backup_dir_path"; then
                 print -r -- "❌ Failed to backup existing vault at '${local_vault_path}'. Aborting pull."
                 return 1
            fi
        fi

        # Ensure parent directory for the vault exists (e.g., local_archive_base_dir)
        # This is also where the zip will be extracted.
        if ! mkdir -p "$(dirname "$local_vault_path")"; then
             print -r -- "Error: Could not create parent directory for vault '${local_vault_path}'. Aborting pull."
             # Attempt to restore backup if one was made and mv failed to create dir
             if [[ -n "$backup_dir_path" && -d "$backup_dir_path" ]]; then
                mv "$backup_dir_path" "$local_vault_path" # Try to put it back
             fi
             return 1
        fi

        # Unzip. The zip file should contain the `vault_name` directory as its top-level item.
        # It will be extracted into `$(dirname "$local_vault_path")`.
        if ! unzip -o "$local_downloaded_zip_path" -d "$(dirname "$local_vault_path")"; then
            print -r -- "❌ Failed to extract '${local_downloaded_zip_path}'."
            # Try to restore backup if one was made and extraction failed
            if [[ -n "$backup_dir_path" && -d "$backup_dir_path" ]]; then
                print -r -- "Attempting to restore from backup '${backup_dir_path}'..."
                rm -rf "$local_vault_path" # Remove potentially partially extracted vault
                if mv "$backup_dir_path" "$local_vault_path"; then
                    print -r -- "✅ Successfully restored from backup."
                else
                    print -r -- "❌ Failed to restore from backup. Manual intervention may be required at '${backup_dir_path}'."
                fi
            fi
            return 1
        fi
        print -r -- "✅ '${vault_name}' successfully pulled and extracted to '${local_vault_path}'."
        print -r -- "Files in vault: $(find "$local_vault_path" -type f 2>/dev/null | wc -l)"

        # Optional: Clean up downloaded zip file
        # print -r -- "Cleaning up downloaded zip file '${local_downloaded_zip_path}'..."
        # rm -f "$local_downloaded_zip_path"

    # --- PUSH LOGIC ---
    elif [[ "$direction" == "push" ]]; then
        local timestamp
        timestamp=$(date "+%Y%m%d_%H%M%S")
        local zip_filename="${vault_name}_${timestamp}.zip"
        # Zip file will be created in the local_archive_base_dir
        local local_zip_to_create_path="${local_archive_base_dir}/${zip_filename}"

        print -r -- "Pushing '${local_vault_path}' to '${remote_rclone_name}' as '${zip_filename}'"

        if [[ ! -d "$local_vault_path" ]]; then
            print -r -- "Error: Local vault directory '${local_vault_path}' does not exist. Nothing to push."
            return 1
        fi

        local file_count
        file_count=$(find "$local_vault_path" -type f 2>/dev/null | wc -l)
        print -r -- "Zipping ${file_count} files from '${local_vault_path}' into '${local_zip_to_create_path}'..."

        # Create zip of the vault.
        # We `cd` to the parent of `local_vault_path` (i.e., `local_archive_base_dir`)
        # then zip the `vault_name` directory. This ensures the zip archive contains
        # `vault_name/...` as its structure, not the full absolute path.
        # The zip file is created directly at its final local destination `local_zip_to_create_path`.
        if ! (cd "$(dirname "$local_vault_path")" && zip -rq "$local_zip_to_create_path" "$vault_name"); then
            print -r -- "❌ Failed to create zip file '${local_zip_to_create_path}'."
            rm -f "$local_zip_to_create_path" # Clean up potentially partially created/empty zip file
            return 1
        fi

        if [[ ! -f "$local_zip_to_create_path" ]]; then
            print -r -- "❌ Zip file creation reported success, but file not found at '${local_zip_to_create_path}'."
            return 1
        fi

        print -r -- "Created local archive: '${zip_filename}' ($(du -h "$local_zip_to_create_path" | cut -f1))"

        # Ensure the remote target directory exists on rclone remote (rclone mkdir is idempotent)
        if ! rclone mkdir "${remote_base_rclone_path}" 2>/dev/null; then
            # This might not be a fatal error if copy can create it, but good to note.
            print -r -- "Warning: Could not ensure remote directory '${remote_base_rclone_path}' exists (or an error occurred). Attempting upload anyway."
        fi

        print -r -- "Uploading '${zip_filename}' to '${remote_base_rclone_path}'..."
        if ! rclone copy "$local_zip_to_create_path" "${remote_base_rclone_path}/" --progress; then
            print -r -- "❌ Upload of '${zip_filename}' failed."
            return 1
        fi

        print -r -- "✅ '${vault_name}' successfully zipped and pushed to '${remote_rclone_name}'."

        # Optional: Clean up local zip file after successful upload
        # print -r -- "Cleaning up local zip file '${local_zip_to_create_path}'..."
        # rm -f "$local_zip_to_create_path"

    # --- INVALID DIRECTION ---
    else
        print -r -- "Usage: obsidian_sync [pull|push]"
        print -r -- "  pull: Download and extract most recent '${vault_name}' backup from ${remote_rclone_name}."
        print -r -- "  push: Zip local '${vault_name}' and upload a new backup to ${remote_rclone_name}."
        return 1 # Invalid argument
    fi

    return 0 # Success
}
