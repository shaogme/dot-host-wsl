# Dot-Host-WSL: 基于 NixOS & npins 的自动化系统配置

本仓库提供了一套基于 NixOS 与 NixOS-WSL 的系统配置方案，集成了模块化的内存优化、定时 Git 自动同步与构建升级、精细的 `npins` 外部依赖管理以及预置的多语言与 AI 开发工具链。

---

## 核心特性

1. **npins 依赖管理**
   - 全局采用 `npins` 代替传统 Flakes 或手动 `fetchFromGitHub`/`fetchTarball` 管理外部依赖（如 `nixpkgs`、`nixos-wsl`、`rust-overlay` 等）。
   - 依赖项及锁定版本统一声明在 [npins/sources.json](npins/sources.json) 中，保证系统构建的可复现性与维护便利性。

2. **Lix 引擎与开箱即用开发环境**
   - 默认启用 `lix` (替代默认 CppNix) 以提供更高的评估性能与更友好的错误提示。
   - 整合 `rust-overlay` 提供最新 Stable 与 Nightly 版本的 Rust 工具链（含 `rust-analyzer`、`clippy`、`rustfmt`、`cargo-nextest` 等）。
   - 预装 Node.js LTS、C++ 工具链 (GCC, Clang, CMake, Ninja, GDB)、Python 3、AI 开发工具 (Codex, Claude-Code, OpenCode) 以及系统常用工具 (Git, Ripgrep, JQ, Tmux 等)。

3. **分级内存优化策略 ([modules/base/memory.nix](modules/base/memory.nix))**
   - 提供四种可选模式（`aggressive`, `balanced`, `conservative`, `none`），特别适合低内存或 WSL 环境：
     - **Aggressive (高强度)**: 针对 <1GB 内存环境，使用 100% ZRAM (zstd)、调高 swappiness (150)，限制 Nix 单核心构建 (`cores=1`, `max-jobs=1`)。
     - **Balanced (平衡)**: 针对 <2GB 内存环境，使用 80% ZRAM，限制 dirty bytes，控制 Nix 构建资源 (`cores=2`, `max-jobs=1`)。
     - **Conservative (保守)**: 针对 >=4GB 内存环境，使用 50% ZRAM，允许全核心构建。
   - 通用配置启用 MGLRU (Multi-Grain LRU, `boot.kernelParams = [ "lru_gen_enabled=1" ]`)。

4. **自动化同步与维护服务 ([modules/base/update.nix](modules/base/update.nix))**
   - **Git 远程配置同步 (`base.update.sync`)**: 支持按 Timer 定时从远端 Git 仓库拉取配置（支持破坏性 hard reset 或非破坏性 pull）。
   - **系统自动构建升级 (`base.update.upgrade`)**: 支持基于定时任务的 `nixos-rebuild` 系统更新。
   - **存储与 Garbage Collection (`base.update.gc`)**: 自动执行老旧 Generation 清除及 Nix Store 自动去重优化 (`auto-optimise-store`)。

5. **Docker & CI/CD 工作流**
   - 包含 [docker-compose.yml](docker-compose.yml)，提供挂载本地代码的 `dev` 开发模式与独立镜像运行的 `standalone` 模式。
   - 自动化 CI Workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)): 自动校验 `npins verify` 与执行 `nix-build tests/eval.nix` 静态评估测试。
   - 每日自动依赖更新 Workflow ([.github/workflows/update.yml](.github/workflows/update.yml)): 定时运行 `npins update`，若有变动自动提交 PR 并触发自动合并。

---

## 目录结构

```text
.
├── configuration.nix         # 主 NixOS 配置文件
├── modules/
│   └── base/                 # 系统基础模块
│       ├── default.nix       # 模块入口，配置 SSH、Locale、TimeZone 等
│       ├── memory.nix        # 内存优化配置模块 (Aggressive / Balanced / Conservative)
│       └── update.nix        # 定时 Git 同步、自动升级与 GC 维护模块
├── npins/                    # npins 依赖锁定及定义文件
│   ├── default.nix           # npins 自动生成的导入入口
│   └── sources.json          # 依赖资源描述文件
├── docs/                     # 项目文档目录
│   └── npins/                # npins 使用说明与测试文档
│       ├── cli.md            # npins 命令行工具使用指南
│       ├── usage.md          # Nix 代码中引用与覆盖依赖指南
│       └── testing.md        # 静态评估与 VM 测试指南
├── tests/                    # 测试脚本
│   └── eval.nix              # 系统配置静态评估测试
├── docker-compose.yml        # Docker 开发容器配置文件
├── AGENTS.md                 # AI Agent 协作规范与开发工作流指南
└── README.md                 # 项目说明文档
```

---

## 依赖管理指南 (npins)

本项目引入的所有外部 Nix 依赖均由 `npins` 管理，避免依赖散落或使用不稳定的网络下载。

### 常用命令

1. **查看当前依赖状态**:
   ```bash
   npins status
   ```

2. **添加新依赖**:
   ```bash
   # 添加 GitHub 仓库
   npins add github <owner> <repo> [--branch <branch>]
   
   # 添加 Nix Channel
   npins add channel <name> <url>
   ```

3. **更新所有依赖**:
   ```bash
   npins update
   ```

4. **校验依赖哈希值**:
   ```bash
   npins verify
   ```

### 本地覆盖与调试

若需要在本地临时修改某个外部依赖进行调试，可通过环境变量覆盖，无需修改 [npins/sources.json](npins/sources.json)：

```bash
export NPINS_OVERRIDE_nixos-wsl=./path/to/local/nixos-wsl
nixos-rebuild switch
```

详细操作规范请参阅 [docs/npins/cli.md](docs/npins/cli.md) 及 [docs/npins/usage.md](docs/npins/usage.md)。

---

## 测试与验证

在提交配置更改之前，需确保配置的正确性与完整性。

### 运行静态配置评估测试

系统提供了 [tests/eval.nix](tests/eval.nix) 用于对系统配置进行求值检查：

```bash
nix-build tests/eval.nix
```

如果输出 `Evaluation check passed...` 并成功生成产物，则说明配置求值无误。

详细测试规范请参阅 [docs/npins/testing.md](docs/npins/testing.md)。

---

## 使用与部署

### 在 NixOS / WSL 环境直接应用配置

1. 克隆本仓库到目标机器：
   ```bash
   git clone https://github.com/shaogme/dot-host-wsl.git
   cd dot-host-wsl
   ```

2. 构建并应用配置：
   ```bash
   nixos-rebuild switch -I nixos-config=./configuration.nix
   ```

### 使用 Docker 开发容器环境

1. 启动本地开发容器（端口映射 2222）：
   ```bash
   docker compose up -d dev
   ```

2. 通过 SSH 连接开发容器：
   ```bash
   ssh root@localhost -p 2222
   ```

---

## 规范与约定

- 任何外部依赖的变更必须提交修改后的 [npins/sources.json](npins/sources.json)。
- 严禁手动修改 [npins/default.nix](npins/default.nix)。
- 为确保 AI 助手和协同开发者的统一规范，请参考 [AGENTS.md](AGENTS.md)。
