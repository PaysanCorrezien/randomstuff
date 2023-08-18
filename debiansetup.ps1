Write-Host "Installing curl and setting passwordless sudo..."
wsl sudo apt update
wsl sudo apt install curl -y
# Prompt for the WSL sudo password
$credential = Get-Credential -Message "Enter your WSL sudo password" -UserName "$($username)"

# Store the sudo password in a variable
$sudoPassword = $credential.Password | ConvertFrom-SecureString -AsPlainText

# Use the provided password to execute the sudo command in WSL
echo $sudoPassword | wsl sudo -S sh -c "echo '$username ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/$username"


Write-Host "Downloading your Git repository..."
wsl sudo apt install -y git
wsl git clone https://github.com/PaysanCorrezien/randomstuff /home/$($username)/install

Write-Host "Executing the setup.sh script..."
wsl bash /home/$($username)/install/setup.sh
