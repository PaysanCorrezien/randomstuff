Write-Host "Installing curl"
wsl sudo apt update
wsl sudo apt install curl -y

Write-Host "Downloading your Git repository..."
wsl sudo apt install -y git
# wsl git clone https://github.com/PaysanCorrezien/randomstuff /home/$($username)/install
wsl bash -c 'git clone https://github.com/PaysanCorrezien/randomstuff /home/$USER/install'

Write-Host "Executing the setup.sh script..."
wsl bash -c 'chmod +x /home/$USER/install/debian.sh'
wsl bash -c '/home/$USER/install/debian.sh'
