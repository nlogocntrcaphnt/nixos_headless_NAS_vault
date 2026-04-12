sudo rsync -uParv ~/Documents/nixos_config/configuration.nix /etc/nixos/

git add .
git commit -m "automated update from script"
#git remote add origin https://github.com/nlogocntrcaphnt/nixos_headless_NAS_vault.git
git push -u origin main
