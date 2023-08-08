
# Install
On windows, launch powershell as admin on fresh machine :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; iex (iwr -UseBasicParsing -Uri 'https://raw.githubusercontent.com/PaysanCorrezien/randomstuff/main/initialise.ps1').Content
``` 


## will be removed once script tested 
```bash
sudo apt install curl
```

```bash
curl -L https://raw.githubusercontent.com/paysancorrezien/randomstuff/main/setup.sh | bash
```
## end remove

# Todo 

## Linux side
- [ ] Lunarvim install adapt
- [ ] nerdfonts install run as user 
- [ ] setup git 
- [ ] secrets
- [ ] docs
- [ ] python dep for lunarvim wrong
- [ ] rewrite in bash 

## Windows
- [ ] install nerdfonts too 
- [ ] Download and execute real cleanup utils to debloat
- [ ] reboot after install wsl 
- [ ] Configure windows terminal ( install + set nerdfonts ) , upload json with correct conf , automatic install json config file
