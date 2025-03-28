
# Key bindings
bindkey -e
typeset -g -A key
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char

# Useful aliases and functions
# Create a directory and cd into it
function take() {
  mkdir -p $1
  cd $1
}

# Enable auto-cd
setopt auto_cd

# History settings
HISTSIZE=20000
SAVEHIST=20000
HISTFILE=~/.zsh_history
setopt share_history
setopt hist_ignore_dups

# Aliases & Arch Linux package management
alias pacupdate="sudo pacman -Syu"
alias pacinstall="sudo pacman -S"
alias pacremove="sudo pacman -Rs"
alias pacsearch="pacman -Ss"
alias zshrc="nvim ~/.zshrc"


# Add handy aliases
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'

# Environment Variables
export EDITOR=nvim


# Prompt Modification
PROMPT='%F{blue}%~%f %# '

# This loads the Zsh completion system module.
# -U flag prevents alias expansion during function loading.
# -z flag forces zsh-style autoloading.
autoload -Uz compinit
compinit

# Menu-Like Interface
zstyle ':completion:*' menu select

obsidian_sync() {
    local direction=$1
    local source
    local destination
    local exit_code
    local vault_folder="FoxVault"
    local zip_file="FoxVault.zip"
    local local_vault_path="$HOME/ProtonDrive/Archives/Obsidian/$vault_folder"
    local local_zip_path="$HOME/ProtonDrive/Archives/Obsidian/$zip_file"
    local remote_base="ProtonDrive:Archives/Obsidian"

    # Check if required tools are installed
    if ! command -v rclone &> /dev/null; then
        echo "Error: rclone is not installed. Please install it first."
        return 1
    fi

    if ! command -v zip &> /dev/null || ! command -v unzip &> /dev/null; then
        echo "Error: zip/unzip utilities are not installed. Please install them first."
        return 1
    fi

    # Check if ProtonDrive remote is configured
    if ! rclone listremotes | grep -q "ProtonDrive:"; then
        echo "Error: ProtonDrive remote is not configured in rclone."
        echo "Please run 'rclone config' to set up your ProtonDrive remote."
        return 1
    fi

    # Pull: Download zip from ProtonDrive and extract
    if [[ "$direction" == "pull" ]]; then
        echo "Pulling FoxVault from ProtonDrive..."

        # Create local directory if it doesn't exist
        mkdir -p "$(dirname "$local_zip_path")"

        # Check if remote zip exists
        if ! rclone lsf "$remote_base/$zip_file" &> /dev/null; then
            echo "Error: Remote zip file '$remote_base/$zip_file' does not exist."
            return 1
        fi

        # Download the zip file
        echo "Downloading $zip_file from ProtonDrive..."
        rclone copy "$remote_base/$zip_file" "$(dirname "$local_zip_path")" --progress
        exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
            echo "❌ Failed to download the zip file (error code $exit_code)."
            return $exit_code
        fi

        # Extract the zip file
        echo "Extracting $zip_file to $local_vault_path..."

        # Backup existing vault if it exists
        if [[ -d "$local_vault_path" ]]; then
            local backup_dir="${local_vault_path}_backup_$(date +%Y%m%d_%H%M%S)"
            echo "Backing up existing vault to $backup_dir"
            mv "$local_vault_path" "$backup_dir"
        fi

        # Create destination directory
        mkdir -p "$local_vault_path"

        # Extract
        unzip -o "$local_zip_path" -d "$(dirname "$local_vault_path")"
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            echo "✅ FoxVault successfully pulled and extracted."
            echo "Files in vault: $(find "$local_vault_path" -type f | wc -l)"
        else
            echo "❌ Failed to extract the vault (error code $exit_code)."
            # Try to restore backup if available
            if [[ -d "$backup_dir" ]]; then
                echo "Restoring from backup..."
                rm -rf "$local_vault_path"
                mv "$backup_dir" "$local_vault_path"
            fi
            return $exit_code
        fi

    # Push: Zip local vault and upload to ProtonDrive
    elif [[ "$direction" == "push" ]]; then
        echo "Pushing FoxVault to ProtonDrive..."

        # Check if local vault exists
        if [[ ! -d "$local_vault_path" ]]; then
            echo "Error: Local vault directory '$local_vault_path' does not exist."
            return 1
        fi

        # Count files before zipping
        local file_count=$(find "$local_vault_path" -type f | wc -l)
        echo "Zipping $file_count files from $local_vault_path..."

        # Create zip of the vault (in the same directory as the vault)
        cd "$(dirname "$local_vault_path")"
        zip -r "$zip_file" "$vault_folder" -q
        exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
            echo "❌ Failed to create zip file (error code $exit_code)."
            return $exit_code
        fi

        # Check zip file was created
        if [[ ! -f "$local_zip_path" ]]; then
            echo "❌ Zip file creation failed."
            return 1
        fi

        echo "Created $zip_file ($(du -h "$local_zip_path" | cut -f1))"

        # Ensure the remote directory exists
        rclone mkdir "$remote_base" 2>/dev/null

        # Upload only the zip file
        echo "Uploading $zip_file to ProtonDrive..."
        rclone copy "$local_zip_path" "$remote_base" --progress
        exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            echo "✅ FoxVault successfully zipped and pushed to ProtonDrive."
        else
            echo "❌ Upload failed with error code $exit_code."
            return $exit_code
        fi

    else
        echo "Usage: obsidian_sync [pull|push]"
        echo "  pull: Download and extract FoxVault from ProtonDrive"
        echo "  push: Zip and upload FoxVault to ProtonDrive"
        return 1
    fi

    return 0
}

