#!/bin/bash

# Variables
ZSH_PATH="/usr/bin/zsh"

print_error() {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED}[ERROR]${NC} $1"
}

install_packages() {
    echo "Installing essential packages..."
    sudo apt update
    sudo apt install -y curl zsh fzf git ripgrep fd-find zoxide || print_error "Failed to install packages"
    sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting || print_error "Failed to install Zsh completion and syntax highlighting"
}

install_zap() {
    if ! check_pass tailscale "zap"; then
    echo "Installing Zap for Zsh..."
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/release-v1/install.zsh) || print_error "Failed to install Zap for Zsh"
    fi
}

change_shell_to_zsh() {
    echo "Changing shell to zsh..."
    chsh -s "$ZSH_PATH" || print_error "Failed to change shell to zsh"
}

basic_zsh_setup() {
    local identifier="# Basic Zsh setup added by script"

    if grep -qF "$identifier" ~/.zshrc; then
        echo "Basic Zsh setup already added to .zshrc. Skipping..."
    else
        echo "Setting up basic Zsh configuration..."
        {
            echo ""  # Ensures starting on a new line
            echo "$identifier"
            echo "source ~/.local/share/fzf-tab/fzf-tab.plugin.zsh"
            echo "eval \"\$(zoxide init zsh)\""
            echo "alias v='nvim'"
            echo "alias md='mkdir'"
            echo "alias rm='rm -irv'"
            echo "alias rmf='rm -rf'"
            echo "alias x='chmod +x'"
            echo "alias ..='cd ../'"
            echo "alias ...='cd ../../'"
            echo "alias ....='cd ../../../'"
            echo "alias .....='cd ../../../../'"
            echo "source /usr/share/doc/fzf/examples/key-bindings.zsh"
            echo "export FZF_DEFAULT_OPTS='--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8'"
            echo "export FZF_CTRL_T_COMMAND='\$FZF_DEFAULT_COMMAND'"
            echo "export FZF_CTRL_T_OPTS='--preview \"batcat -n --color=always {}\"'"
            echo "export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'"
            echo "export FZF_CTRL_R_OPTS='--preview \"echo {}\" --preview-window up:3:hidden:wrap --bind \"ctrl-/:toggle-preview\" --bind \"ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort\" --color header:italic --header \"Press CTRL-Y to copy command into clipboard\"'"
            echo "host_ip=\$(hostname -I | awk '{print \$1}')" >> ~/.zshrc
            echo "export PS1=\"\$PS1 (\$host_ip) --> \"" >> ~/.zshrc
        } >> ~/.zshrc
    fi
}

get_latest_tag() {
    local repo=$1
    curl --silent "https://api.github.com/repos/$repo/tags" |
    grep '"name":' |
    sed -E 's/.*"([^"]+)".*/\1/' |
    head -n 1
}
check_pass() {
    local command_name=$1
    local description=$2
    if command -v "$command_name" >/dev/null 2>&1; then
        echo "$description is already installed. Skipping installation."
        return 0  # Return with success (0) to indicate skipping
    else
        return 1  # Return with failure (1) to indicate installation should proceed
    fi
}

install_neovim() {
    if ! check_pass nvim "Neovim"; then
    echo "Installing Neovim from source..."

    NEOVIM_VERSION=$(get_latest_tag "neovim/neovim")
    curl -L https://github.com/neovim/neovim/releases/download/"$NEOVIM_VERSION"/nvim-linux64.tar.gz -o /tmp/nvim-linux64.tar.gz || print_error "Failed to download Neovim"

    if [[ -f /tmp/nvim-linux64.tar.gz ]]; then
        echo "Extracting Neovim release..."
        sudo tar xf /tmp/nvim-linux64.tar.gz -C /usr/local/ || print_error "Failed to extract Neovim"
    else
        print_error "Neovim tar.gz file not found"
    fi
    echo "Copying Neovim binary to /usr/bin/"
    sudo cp /usr/local/nvim-linux64/bin/nvim /usr/bin/ || print_error "Failed to copy Neovim binary"
    fi
}

handle_fd_find() {
    if [ ! -f "$HOME/.local/bin/fd" ]; then
        echo "Creating a symbolic link for fd-find..."
        mkdir -p "$HOME/.local/bin"
        ln -s "$(which fdfind)" "$HOME/.local/bin/fd"
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "fd is already set up. Skipping."
    fi
}


fzf_tab() {
    local fzf_tab_dir="$HOME/.local/share/fzf-tab"

    if [ ! -d "$fzf_tab_dir" ]; then
        echo "Cloning fzf-tab..."
        git clone https://github.com/Aloxaf/fzf-tab "$fzf_tab_dir" || print_error "Failed to clone fzf-tab"
    else
        echo "fzf-tab is already installed. Skipping."
    fi
}

install_docker() {
    if ! check_pass docker "Docker"; then
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update 
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || print_error "Failed to install Docker and Docker Compose"

    echo "Installing Lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || print_error "Failed to install Lazydocker"
    fi
}

install_tailscale() {
    if ! check_pass tailscale "Tailscale"; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh || print_error "Failed to install Tailscale"
    fi
}

optional_install() {
    local install_function=$1
    local description=$2

    echo "Debug: About to install $description"
    read -p "Install $description? [y/N]: " -r response
    echo ""

    case $response in
        [Yy]* ) $install_function;;
        * ) echo "Skipping $description installation.";;
    esac
}


main() {
    install_packages
    optional_install install_docker "Docker"
    optional_install install_tailscale "Tailscale"
    change_shell_to_zsh
    install_zap
    install_neovim
    basic_zsh_setup
    handle_fd_find
    install_fzf_tab
}

main
