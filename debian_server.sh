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
    echo "Installing Zap for Zsh..."
    zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/release-v1/install.zsh) || print_error "Failed to install Zap for Zsh"
}

change_shell_to_zsh() {
    echo "Changing shell to zsh..."
    chsh -s "$ZSH_PATH" || print_error "Failed to change shell to zsh"
}

basic_zsh_setup() {
    echo "Setting up basic Zsh configuration..."
    {
        echo "# attempt with fzf tab"
        echo "source ~/.local/share/fzf-tab/fzf-tab.plugin.zsh"
        echo "eval \"\$(zoxide init zsh)\""
        echo "alias v=\"nvim\""
        echo "alias md=\"mkdir\""
        echo "alias rm=\"rm -irv\""
        echo "alias rmf=\"rm -rf\""
        echo "alias x=\"chmod +x\""
        echo "alias ..=\"cd ../\""
        echo "alias ...=\"cd ../../\""
        echo "alias ....=\"cd ../../../\""
        echo "alias .....=\"cd ../../../../\""
        echo "source /usr/share/doc/fzf/examples/key-bindings.zsh"
        echo "export FZF_DEFAULT_OPTS=\"--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8\""
        echo "export FZF_CTRL_T_COMMAND=\"\$FZF_DEFAULT_COMMAND\""
        echo "export FZF_CTRL_T_OPTS=\"--preview 'batcat -n --color=always {}'\""
        echo "export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'"
        echo "export FZF_CTRL_R_OPTS=\"--preview 'echo {}' --preview-window up:3:hidden:wrap --bind 'ctrl-/:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort' --color header:italic --header 'Press CTRL-Y to copy command into clipboard'\""
    } >> ~/.zshrc
}

get_latest_tag() {
    local repo=$1
    curl --silent "https://api.github.com/repos/$repo/tags" |
    grep '"name":' |
    sed -E 's/.*"([^"]+)".*/\1/' |
    head -n 1
}

install_neovim() {
    echo "Installing Neovim from source..."

    NEOVIM_VERSION=$(get_latest_tag "neovim/neovim")
    curl -L https://github.com/neovim/neovim/releases/download/"$NEOVIM_VERSION"/nvim-linux64.tar.gz -o /tmp/nvim-linux64.tar.gz || print_error "Failed to download Neovim"

    if [[ -f /tmp/nvim-linux64.tar.gz ]]; then
        echo "Extracting Neovim release..."
        sudo tar xf /tmp/nvim-linux64.tar.gz -C /usr/local/ || print_error "Failed to extract Neovim"
    else
        print_error "Neovim tar.gz file not found"
    fi
}

install_docker() {
    echo "Installing Docker..."

    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-compose || print_error "Failed to install Docker and Docker Compose"

    echo "Installing Lazydocker..."
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || print_error "Failed to install Lazydocker"
}

install_tailscale() {
    echo "Installing Tailscale..."

    curl -fsSL https://pkgs.tailscale.com/stable/debian/$(lsb_release -cs).gpg | sudo apt-key add -
    curl -fsSL https://pkgs.tailscale.com/stable/debian/$(lsb_release -cs).list | sudo tee /etc/apt/sources.list.d/tailscale.list
    sudo apt-get update
    sudo apt-get install -y tailscale || print_error "Failed to install Tailscale"
}

optional_install() {
    local install_function=$1
    local description=$2
    read -p "Do you want to install $description? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $install_function
    fi
}

main() {
    install_packages
    change_shell_to_zsh
    install_zap
    install_neovim
    basic_zsh_setup
    optional_install install_docker "Docker"
    optional_install install_tailscale "Tailscale"
}

main
