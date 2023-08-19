#!/bin/bash

# Variables (hardcoded values)
GITHUB_USER="paysancorrezien"
ZSH_PATH="/usr/bin/zsh"
IP_DNS=192.168.1.1

# WARNING: Missing features:
# Experimental

print_error() {
	RED='\033[0;31m'
	NC='\033[0m' # No Color
	echo -e "${RED}[ERROR]${NC} $1"
}

install_packages() {
	echo "Installing packages..."
	# Example install command. Modify with your package manager of choice
	sudo apt update
	sudo apt install -y curl git unzip python3 python3-pip python3-setuptools python3-venv xclip wget autorandr jq fzf zoxide bat ripgrep tmux exa neofetch zsh || print_error "Failed to install packages"
	sudo apt install -y dnsutils console-setup
}

install_node() {
	echo "Installing Node.js via NVM..."
	source "$HOME"/.nvm/nvm.sh
	nvm install node || print_error "Failed to install Node"
}

change_shell() {
	echo "Changing shell to zsh..."
	chsh -s "$ZSH_PATH" || print_error "Failed to change shell to zsh"
}

install_neovim() {
	echo "Installing Neovim..."

	NEOVIM_VERSION=$(get_latest_tag "neovim/neovim")
	curl -L https://github.com/neovim/neovim/releases/download/"$NEOVIM_VERSION"/nvim-linux64.tar.gz -o /tmp/nvim-linux64.tar.gz || print_error "Failed to download Neovim"

	if [[ -f /tmp/nvim-linux64.tar.gz ]]; then
		echo "Extracting Neovim release..."
		sudo tar xf /tmp/nvim-linux64.tar.gz -C /usr/local/ || print_error "Failed to extract Neovim"
	else
		print_error "Neovim tar.gz file not found"
	fi
}

# HACK: path in dotfiles that are not installed until later
add_neovim_path() {
	echo "Adding Neovim to path..."
	export PATH="$PATH:/usr/local/nvim-linux64/bin" || print_error "Failed to add Neovim to path"
}
refresh_shell() {
	. /etc/profile
}
create_venv() {
	echo "Creating a virtual environment..."
	python3 -m venv ~/myvenv || print_error "Failed to create a virtual environment"
}

activate_venv() {
	echo "Activating the virtual environment..."
	source ~/myvenv/bin/activate || print_error "Failed to activate the virtual environment"
}

install_rust() {
	echo "Installing Rust..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh || print_error "Failed to install Rust"
}

check_branch_exists() {
    local repo=$1
    local branch=$2
    local branches

    branches=$(curl --silent "https://api.github.com/repos/$repo/branches" | grep '"name":' | sed -E 's/.*"([^"]+)".*/\1/')

    [[ $branches == *"$branch"* ]]
}

install_lunarvim() {
	echo "Installing LunarVim..."

	local lunarvim_version
	local neovim_version
	local lunarvim_branch
 	cargo install fd-findcargo install fd-find
	lunarvim_version=$(get_latest_release "LunarVim/LunarVim" | sed 's/v//')
	neovim_version=$(get_latest_release "neovim/neovim" | sed 's/v//')

	lunarvim_branch="release-${lunarvim_version%.*}/neovim-${neovim_version%.*}"

 	if ! check_branch_exists "LunarVim/LunarVim" "$lunarvim_branch"; then
        print_error "Branch $lunarvim_branch does not exist!"
        return 1
	fi

	echo "Installing LunarVim for branch: $lunarvim_branch"

	LV_BRANCH=$lunarvim_branch bash <(curl -s "https://raw.githubusercontent.com/LunarVim/LunarVim/${lunarvim_branch}/utils/installer/install.sh") || print_error "Failed to install LunarVim"
}

# WARNING: NOT realy working on domain ?
configure_wsl() {
	echo "Configuring WSL..."
	echo '[network]
    generateResolvConf = false 
    [automount] 
    root = /mnt/ 
    options = "metadata"' | sudo tee /etc/wsl.conf || print_error "Failed to configure WSL"
}
# NOTE: Debian WSL specific
allow_ping_without_sudo() {
	echo "Allowing ping without sudo..."
	sudo chmod u+s /bin/ping || print_error "Failed to allow ping without sudo"
}
set_dns_wsl() {
	local dns_ip="$1"

	if [ "$dns_ip" = "" ]; then
		print_error "No DNS IP address provided"
		return 1
	fi

	echo "Setting DNS for WSL to $dns_ip..."
	echo "nameserver $dns_ip" | sudo tee /etc/resolv.conf || print_error "Failed to set DNS for WSL"
}

##NOTE: SHELL
install_zap() {
	log "Installing Zap for Zsh..."
	zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/release-v1/install.zsh)
}
change_shell_to_zsh() {
	echo "Changing shell to zsh..."
	chsh -s "$ZSH_PATH" || print_error "Failed to change shell to zsh"
}

# NOTE: Dotfiles
install_chezmoi() {
	echo "Installing chezmoi..."
	curl -fsLS git.io/chezmoi | sh
	sudo mv ./bin/chezmoi /usr/local/bin/
}

clone_dotfiles() {
	echo "Copying dotfiles..."
	git clone --branch main "https://github.com/$GITHUB_USER/dotfiles.git" "$HOME/.local/share/chezmoi" || print_error "Failed to clone dotfiles"
}

# HACK: chezmoi wont apply without template corresponding variable use in my confs files
create_chezmoi_template() {
	echo "Creating chezmoi template..."
	echo '[data]
    git = { name = "Default Name", email = "default@email.com", gpg = "DefaultKey" }' >"$HOME/.config/chezmoi/chezmoi.toml" || print_error "Failed to create chezmoi template"
	chezmoi apply || print_error "Failed to apply chezmoi"
}

setup_chezmoi() {
	echo Initialize chezmoi
	chezmoi init --apply "$GITHUB_USER"

	echo update chezmoi
	chezmoi update
}
install_powershell_on_debian() {
	echo "Installing PowerShell on Debian..."
	curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --yes --dearmor --output /usr/share/keyrings/microsoft.gpg || print_error "Failed to save the public repository GPG keys"
	sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/microsoft-debian-bullseye-prod bullseye main" > /etc/apt/sources.list.d/microsoft.list' || print_error "Failed to register the Microsoft Product feed"
	sudo apt update && sudo apt install -y powershell || print_error "Failed to install PowerShell"
}
sudoers_configuration() {
	echo "Configuring sudoers for $USER..."
	echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/"$USER" || print_error "Failed to configure sudoers"
}

install_fira_code_font() {
	echo "Downloading and installing Fira Code Nerd Font..."
	local fonts_dir="$HOME/.local/share/fonts"
	local version="6.2"
	local zip="Fira_Code_v${version}.zip"

	mkdir -p "$fonts_dir" || print_error "Failed to create font directory"

	curl --fail --location --show-error https://github.com/tonsky/FiraCode/releases/download/"$version/$zip" -o "$zip" || print_error "Failed to download Fira Code zip"

	unzip -o -q -d "$fonts_dir" "$zip" || print_error "Failed to extract Fira Code font files"

	rm -f "$zip" || print_error "Failed to remove the zip file"

	fc-cache -f || print_error "Failed to rebuild font cache"
}

# HACK: for github download
get_latest_release() {
	curl --silent "https://api.github.com/repos/$1/releases/latest" |
		grep '"tag_name":' |
		sed -E 's/.*"([^"]+)".*/\1/'
}

get_latest_tag() {
	curl --silent "https://api.github.com/repos/$1/tags" |
		grep '"name":' |
		sed -E 's/.*"([^"]+)".*/\1/' |
		head -n 1
}
install_lazygit() {
	echo "INFO: Installing Lazygit..."

	# Ensure REPO is set to correct repository
	local REPO="jesseduffield/lazygit"

	local LAZYGIT_VERSION=$(get_latest_release "$REPO")

	# Ensure LAZYGIT_VERSION was fetched correctly
	if [[ -z "$LAZYGIT_VERSION" ]]; then
		print_error "ERROR" "Failed to fetch the latest version of Lazygit."
		return 1
	fi

	local LAZYGIT_URL="https://github.com/${REPO}/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz"

	curl -fsLo lazygit.tar.gz "$LAZYGIT_URL"
	if [[ $? -ne 0 ]]; then
		print_error "ERROR" "Failed to download Lazygit from ${LAZYGIT_URL}."
		return 1
	fi

	tar xf lazygit.tar.gz lazygit
	if [[ $? -ne 0 ]]; then
		print_error "ERROR" "Failed to extract Lazygit archive."
		return 1
	fi

	sudo install lazygit /usr/local/bin
	if [[ $? -ne 0 ]]; then
		print_error "ERROR" "Failed to install Lazygit."
		return 1
	fi

	echo "INFO: Lazygit installed successfully!"
}

install_nvm() {

	echo "Installing NVM..."
	NVM_VERSION=$(get_latest_release "nvm-sh/nvm")
	curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash || print_error "Failed to install NVM"
}

main() {
	install_packages
	sudoers_configuration
	install_nvm
	install_node
	change_shell
	install_zap # Assuming you'd want to keep one of the two.
	install_neovim
	add_neovim_path
	create_venv
	activate_venv
	install_rust
	install_lunarvim
	install_chezmoi
	clone_dotfiles
	setup_chezmoi
	configure_wsl
	allow_ping_without_sudo # Assuming you'd want to keep one of the two.
	set_dns_wsl "$IP_DNS"
	install_lazygit
	install_powershell_on_debian
	install_fira_code_font
	
}

# Call the main function
main
