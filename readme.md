# Install
On windows, launch powershell as admin on fresh machine :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; iex (iwr -UseBasicParsing -Uri 'https://raw.githubusercontent.com/PaysanCorrezien/randomstuff/main/wslsetup.ps1').Content
``` 

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; iex (iwr -UseBasicParsing -Uri 'https://raw.githubusercontent.com/PaysanCorrezien/randomstuff/main/setupw11.ps1').Content
``` 

Once Wsl is running :

```bash
sudo apt update && sudo apt upgrade
sudo apt install curl
```

```bash
curl -L https://raw.githubusercontent.com/paysancorrezien/randomstuff/main/setup.sh | bash
```
## end remove

# Todo 

## Linux Side
- [ ] Lunarvim install adapt
- [ ] Dont prompt for sudoers multi time for wsl setup
- [ ] make this work with less interaction
- [ ] Manage the multiple reboot needed
- [ ] python dep for Lunarvim wrong ? 

## Windows

- [ ] Download and execute real cleanup utils to debloat
- [ ] reboot after install WSL 
