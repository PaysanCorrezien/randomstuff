$username = "dylan"

Write-Host "Enabling WSL and Virtual Machine Platform..."
Start-Process -Wait -NoNewWindow -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
Start-Process -Wait -NoNewWindow -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"

Write-Host "Setting WSL 2 as the default..."
wsl --set-default-version 2

Write-Host "Installing Debian..."
wsl --install -d Debian

Write-Host "Installing curl and setting passwordless sudo..."
wsl sudo apt update
wsl sudo apt install curl -y
echo "$username ALL=(ALL:ALL) NOPASSWD: ALL" | wsl sudo tee /etc/sudoers.d/myusername

Write-Host "Downloading your Git repository..."
wsl sudo apt install -y git
wsl git clone https://github.com/PaysanCorrezien/randomstuff /home/$username/install

Write-Host "Executing the setup.sh script..."
wsl bash /home/$username/install/setup.sh

Write-Host "Running the Ansible playbook on the Windows system..."
wsl ansible-playbook -i "//wsl.localhost/Debian/home/$username/install/localhost," /home/$username/install/windows.yml

