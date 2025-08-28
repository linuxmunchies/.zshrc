#------------------------------------------------------------------------------
# ZSH CONFIGURATION
#------------------------------------------------------------------------------

# Shell options
setopt auto_cd          # Automatically cd to a directory if a command is its name
setopt share_history    # Share history between all concurrent shell sessions
setopt hist_ignore_dups # Do not record an event that was just recorded again

# History settings
HISTFILE=~/.zsh_history # Path to the history file
HISTSIZE=20000          # Maximum number of events stored in internal history
SAVEHIST=20000          # Maximum number of events saved to HISTFILE

# Define colors for use in custom scripts
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

#------------------------------------------------------------------------------
# KEY BINDINGS
#------------------------------------------------------------------------------
[cite_start]bindkey -e # Use Emacs keybindings [cite: 4]

# Navigation & Editing
bindkey '^[[H'  beginning-of-line # Home
bindkey '^[[F'  end-of-line       # End
bindkey '^[[3~' delete-char       # Delete
bindkey '^[[5~' up-line-or-history   # PageUp
bindkey '^[[6~' down-line-or-history # PageDown
[cite_start]bindkey '^[[A' up-line-or-search    # UpArrow [cite: 5]
bindkey '^[[B' down-line-or-search  # DownArrow
bindkey '^[[C' forward-char         # RightArrow
bindkey '^[[D' backward-char        # LeftArrow

#------------------------------------------------------------------------------
# ALIASES, FUNCTIONS, AND ENVIRONMENT
#------------------------------------------------------------------------------

# Environment Variables
export EDITOR=nvim
# [cite_start]Use correct TERM variable for SSH sessions from Kitty [cite: 2, 3]
[[ "$TERM" == "xterm-kitty" ]] && alias ssh="TERM=xterm-256color ssh"

# General Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias zshrc="nvim ~/.zshrc"
alias c='clear'
alias ..='cd ..'
alias ll='ls -lha'
alias la='ls -A'

# --- Distro-Aware Package Management Aliases ---
# Detects the OS and sets aliases accordingly.
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
        arch|artix|endeavouros|manjaro)
            __zsh_distro_id="arch"
            alias update="sudo pacman -Syu"
            alias install="sudo pacman -S"
            [cite_start]alias remove="sudo pacman -Rs" # [cite: 6]
            alias search="pacman -Ss"
            ;;
        fedora|nobara)
            __zsh_distro_id="fedora"
            alias update="sudo dnf upgrade --refresh"
            alias install="sudo dnf install"
            alias remove="sudo dnf remove"
            alias search="dnf search"
            ;;
        *)
            __zsh_distro_id="unknown"
            ;;
    esac
fi

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
# [cite_start]Load Zsh's completion system, preventing alias expansion and forcing zsh-style autoloading. [cite: 7, 8]
autoload -Uz compinit
compinit

# --- Improved Completion Styling ---
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Use ls colors for file completions
zstyle ':completion:*:*:*:*:*' 'group-name'             # Group completions by type
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # Case-insensitive completion

#------------------------------------------------------------------------------
# SUGGESTED ENHANCEMENTS (PLUGINS)
#------------------------------------------------------------------------------
# For a much better shell experience, install these plugins via your package manager
# (e.g., `sudo dnf install zsh-autosuggestions zsh-syntax-highlighting`)
# then uncomment the lines below.

# Zsh Autosuggestions (suggests commands as you type)
# if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
#   source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# fi

# Zsh Syntax Highlighting (highlights commands and syntax in real time)
# if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
#   source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# fi

# Safer 'rm' command using trash-cli (install with 'pip install trash-cli')
# alias rm='trash'

#------------------------------------------------------------------------------
# CUSTOM FUNCTIONS
#------------------------------------------------------------------------------

# --- Distro-Aware FZF Package Search ---
# Helper function for Arch Linux
_fzf_arch() {
    [cite_start]if ! command -v pacman &>/dev/null; then [cite: 11]
        [cite_start]print -r -- "${RED}Error: pacman not found.${NC}" && return 1 [cite: 12]
    fi
    [cite_start]pacman -Qq | fzf --preview="pacman -Qi {1}" --preview-window="right:60%" --height=40% --layout=reverse --border [cite: 13]
}

# Helper function for Fedora
_fzf_fedora() {
    if ! command -v dnf &>/dev/null; then
        print -r -- "${RED}Error: dnf not found.${NC}" && return 1
    fi
    rpm -qa --qf '%{NAME}\n' | fzf --preview="dnf info {1}" --preview-window="right:60%" --height=40% --layout=reverse --border
}

# fzf_pkgs: Interactively search installed packages using fzf.
# Automatically uses the correct package manager for your system.
fzf_pkgs() {
    [cite_start]if ! command -v fzf &>/dev/null; then [cite: 9]
        [cite_start]print -r -- "${RED}Error: fzf is not installed.${NC}" && return 1 [cite: 10]
    fi

    case "$__zsh_distro_id" in
        arch)   _fzf_arch ;;
        fedora) _fzf_fedora ;;
        *)      print -r -- "${RED}Error: Unsupported distribution for fzf_pkgs.${NC}" && return 1 ;;
    esac
}

# [cite_start]obsidian_sync: Synchronize Obsidian vault with a remote rclone destination. [cite: 14]
# [cite_start]Requires: rclone, zip, unzip [cite: 15]
obsidian_sync() {
    local direction="$1"
    local readonly vault_name="FoxVault"
    local readonly local_archive_base_dir="$HOME/ProtonDrive/Archives/Obsidian"
    local readonly remote_rclone_name="ProtonDrive"
    [cite_start]local readonly remote_archive_path_on_drive="Archives/Obsidian" [cite: 16]
    local readonly local_vault_path="${local_archive_base_dir}/${vault_name}"
    local readonly remote_base_rclone_path="${remote_rclone_name}:${remote_archive_path_on_drive}"

    _obsidian_sync_check_prerequisites() {
        [cite_start]for tool in rclone zip unzip; do [cite: 17]
            [cite_start]if ! command -v "$tool" &>/dev/null; then [cite: 18]
                [cite_start]print -r -- "${RED}Error: Required tool '${tool}' is not installed.${NC}" && return 1 [cite: 19]
            fi
        done
        [cite_start]if ! rclone listremotes | grep -q "^${remote_rclone_name}:"; then [cite: 20]
            [cite_start]print -r -- "${RED}Error: rclone remote '${remote_rclone_name}:' is not configured.${NC}" [cite: 21] [cite_start]&& return 1 [cite: 22]
        fi
        return 0
    }

    if ! [cite_start]_obsidian_sync_check_prerequisites; then return 1; fi [cite: 23]

    [cite_start]if [[ "$direction" == "pull" ]]; then [cite: 24]
        print -r -- "${BLUE}Pulling '${vault_name}' from '${remote_rclone_name}'...${NC}"
        local latest_backup_filename
        latest_backup_filename=$(rclone lsf "${remote_base_rclone_path}" --include "${vault_name}_*.zip" 2>/dev/null | sort -r | head -n 1)

        [cite_start]if [[ -z "$latest_backup_filename" ]]; then [cite: 25]
            [cite_start]print -r -- "${RED}Error: No backups found in '${remote_base_rclone_path}'.${NC}" && return 1 [cite: 26]
        fi
        
        local remote_zip_to_download="${remote_base_rclone_path}/${latest_backup_filename}"
        local local_downloaded_zip_path="${local_archive_base_dir}/${latest_backup_filename}"

        print -r -- "-> Latest backup: ${YELLOW}${latest_backup_filename}${NC}"
        [cite_start]if ! mkdir -p "$local_archive_base_dir"; then print -r -- "${RED}Error: Could not create '${local_archive_base_dir}'.${NC}" && return 1; fi [cite: 27, 28]

        print -r -- "-> Downloading..."
        [cite_start]if ! rclone copy "$remote_zip_to_download" "$local_archive_base_dir/" --progress; then [cite: 29]
            [cite_start]print -r -- "${RED}❌ Download failed.${NC}" && return 1 [cite: 30]
        fi

        local backup_dir_path=""
        [cite_start]if [[ -d "$local_vault_path" ]]; then [cite: 31]
            backup_dir_path="${local_vault_path}_backup_$(date +%Y%m%d_%H%M%S)"
            print -r -- "-> Backing up existing vault to ${YELLOW}${backup_dir_path}${NC}"
            [cite_start]if ! mv "$local_vault_path" "$backup_dir_path"; then [cite: 32]
                 [cite_start]print -r -- "${RED}❌ Failed to backup existing vault. Aborting.${NC}" && return 1 [cite: 33]
            fi
        fi

        print -r -- "-> Extracting archive..."
        [cite_start]if ! unzip -o "$local_downloaded_zip_path" -d "$(dirname "$local_vault_path")"; then [cite: 34, 38]
            print -r -- "${RED}❌ Failed to extract archive.${NC}"
            [cite_start]if [[ -n "$backup_dir_path" && -d "$backup_dir_path" ]]; then [cite: 35, 36, 39, 40]
                print -r -- "-> Attempting to restore from backup..."
                rm -rf "$local_vault_path"
                [cite_start]if mv "$backup_dir_path" "$local_vault_path"; then [cite: 41]
                    [cite_start]print -r -- "${GREEN}✅ Successfully restored from backup.${NC}" [cite: 41]
                else
                    [cite_start]print -r -- "${RED}❌ Failed to restore from backup. Manual intervention required.${NC}" [cite: 42]
                [cite_start]fi [cite: 43]
            fi
            return 1
        fi
        [cite_start]print -r -- "${GREEN}✅ '${vault_name}' successfully pulled.${NC}" [cite: 44]

    [cite_start]elif [[ "$direction" == "push" ]]; then [cite: 45]
        local timestamp=$(date "+%Y%m%d_%H%M%S")
        local zip_filename="${vault_name}_${timestamp}.zip"
        local local_zip_to_create_path="${local_archive_base_dir}/${zip_filename}"

        print -r -- "${BLUE}Pushing '${local_vault_path}' to '${remote_rclone_name}'...${NC}"

        if [[ ! [cite_start]-d "$local_vault_path" ]]; then [cite: 46]
            [cite_start]print -r -- "${RED}Error: Local vault '${local_vault_path}' does not exist.${NC}" && return 1 [cite: 47]
        fi

        print -r -- "-> Creating zip archive..."
        # [cite_start]Create zip with relative paths by cd'ing into the parent directory first. [cite: 48, 49, 50]
        if ! (cd "$(dirname "$local_vault_path")[cite_start]" && zip -rq "$local_zip_to_create_path" "$vault_name"); then [cite: 51]
            [cite_start]print -r -- "${RED}❌ Failed to create zip file.${NC}" && rm -f "$local_zip_to_create_path" && return 1 [cite: 52]
        fi
        
        if [[ ! [cite_start]-f "$local_zip_to_create_path" ]]; then print -r -- "${RED}❌ Zip file not found after creation.${NC}" && return 1; fi [cite: 53, 54]

        print -r -- "-> Uploading ${YELLOW}${zip_filename}${NC}..."
        [cite_start]rclone mkdir "${remote_base_rclone_path}" 2>/dev/null [cite: 55, 56, 57]
        [cite_start]if ! rclone copy "$local_zip_to_create_path" "${remote_base_rclone_path}/" --progress; then [cite: 58]
            [cite_start]print -r -- "${RED}❌ Upload failed.${NC}" && return 1 [cite: 59]
        fi

        [cite_start]print -r -- "${GREEN}✅ '${vault_name}' successfully pushed.${NC}" [cite: 60]

    else
        [cite_start]print -r -- "Usage: obsidian_sync [pull|push]" [cite: 61, 62]
    fi
    return 0
}
