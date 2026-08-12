# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

let
  sources = import ./npins;
in
{
  imports = [
    # include NixOS-WSL modules tracked by npins
    "${sources.nixos-wsl}/modules"
    ./modules/base
  ];

  # 启用 Lix 代替默认的 CppNix
  nix.package = pkgs.lixPackageSets.git.lix;

  # 应用 rust-overlay
  nixpkgs.overlays = [ (import sources.rust-overlay) ];

  # 基础配置与内存调优
  base.enable = true;
  base.memory.mode = "aggressive";
  base.container.podman.enable = true;

  base.update = {
    enable = true;
    sync = {
      enable = true;
      url = "https://github.com/shaogme/dot-host-wsl";
      branch = "main";
    };
    upgrade.enable = true;
  };

  # WSL 配置
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  # 启用 SSH Agent 透传，共享 Windows 的 SSH 密钥/凭据
  wsl.ssh-agent.enable = true;

  wsl.wslConf = {
    # 引导与 systemd
    boot = {
      systemd = true;                 # 使用 systemd 作为 init 进程（建议保持开启）
      # command = "echo 'WSL Started'";# 启动时执行的自定义脚本命令
    };

    # Windows 驱动器挂载设置
    automount = {
      enabled = true;
      root = "/mnt";                  # Windows 盘符挂载点根目录
      options = "metadata,uid=1000,gid=100,umask=022,fmask=011"; # 挂载权限参数
      mountFsTab = false;             # 保持为 false，由 systemd 自动挂载
    };

    # 网络设置
    network = {
      generateHosts = true;           # 自动生成 /etc/hosts
      generateResolvConf = true;      # 自动生成 /etc/resolv.conf
      hostname = "nixos-wsl";          # 自定义 WSL 实例的主机名
    };

    # 底层启动用户
    user = {
      default = "nixos";
    };
  };

  # 启用 nix-ld 支持运行非 Nix 打包的动态链接二进制程序
  programs.nix-ld.enable = true;

  # 启用 Zsh 及其自动联想与语法高亮功能
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # 设置默认 Shell 为 Zsh
  users.defaultUserShell = pkgs.zsh;

  # 开发工具集：Rust, Node.js LTS, C++ 工具链, Python 3 等
  environment.systemPackages = with pkgs; [
    # 1. 最新 Rust 工具链
    (rust-bin.stable.latest.minimal.override {
      extensions = [ "rust-src" "rust-analyzer" "rustfmt" "clippy" "rust-docs" ];
    })
    (lib.lowPrio (rust-bin.nightly.latest.minimal.override {
      extensions = [ "rust-src" ];
    }))
    cargo-nextest
    cargo-expand
    cargo-watch
    cargo-edit
    cargo-audit
    cargo-deny
    cargo-binstall

    # 2. Node.js LTS & Corepack
    nodejs
    corepack

    # 3. C++ 工具链
    gcc
    gnumake
    cmake
    clang
    gdb
    pkg-config
    ninja

    # 4. 包管理与环境工具
    pixi
    distrobox

    # 5. 常用开发与实用工具
    git
    git-lfs
    gh
    curl
    wget
    ripgrep
    fd
    jq
    tmux
    htop
    zip
    unzip
    p7zip
  ];

  system.stateVersion = "26.05";
}
