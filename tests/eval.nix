let
  sources = import ../npins;
  pkgs = import sources.nixos-unstable {};
  eval = import (pkgs.path + "/nixos/lib/eval-config.nix") {
    modules = [ ../configuration.nix ];
    inherit pkgs;
  };
  wslEnable = pkgs.lib.boolToString eval.config.wsl.enable;
  wslUser = eval.config.wsl.defaultUser;
  baseEnable = pkgs.lib.boolToString eval.config.base.enable;
  syncUrl = eval.config.base.update.sync.url;
  memoryMode = eval.config.base.memory.mode;
in
pkgs.runCommand "static-check" {} ''
  echo "Checking WSL & Base configuration evaluation..."
  if [[ "${wslEnable}" == "true" \
     && "${wslUser}" == "nixos" \
     && "${baseEnable}" == "true" \
     && "${syncUrl}" == "https://github.com/shaogme/dot-host-wsl" \
     && "${memoryMode}" == "aggressive" ]]; then
    echo "Evaluation check passed: wsl, base, syncUrl, memory.mode=aggressive"
    touch $out
  else
    echo "Evaluation check failed!"
    exit 1
  fi
''
