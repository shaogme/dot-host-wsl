# /etc/nixos-extra/btrfs-hardware.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  # 1. 确保 WSL 内核加载 btrfs 支持工具
  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
  ];

  # 2. 配置 btrfs 文件系统挂载项与压缩选项
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root"; # 也可以使用 UUID="c2f7ec4c-04f2-4c44-abc6-0965e620cbe4"（格式化后 UUID 会改变，需重新填入）
    fsType = "btrfs";
    options = [ 
      "subvol=@" 
      "compress=zstd:1" # 开启 zstd 透明压缩
      "noatime" 
      "space_cache=v2" 
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd:1" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:1" "noatime" ];
  };
}