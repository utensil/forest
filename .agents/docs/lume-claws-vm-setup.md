# Lume macOS VM Setup Recap - "mimi"

**Date Created**: 2026-02-13  
**VM Name**: mimi (originally created as "claws", renamed on 2026-02-16)  
**Purpose**: Isolated macOS development environment with OpenClaw

---

## VM Configuration

### Basic Specs
- **OS**: macOS 15.6.1 Sequoia (Build 24G90)
- **Architecture**: ARM64 (Apple Silicon)
- **CPU**: 4 cores
- **Memory**: 8GB
- **Disk**: 100GB (fully allocated)
- **Display**: 1024x768
- **Network**: NAT mode
- **IP Address**: 192.168.64.9

### Storage Location
- **Current Location**: `home` (default lume storage)
- **Original Location**: `/Volumes/L8T-1-exfat/lume/claws` (external drive)
- **Note**: VM was moved from external storage to home storage and renamed to "mimi"

### Creation Command (Original)
```bash
lume create claws \
  --os macos \
  --ipsw /Volumes/L8T-1-exfat/Downloads/macos.ipsw \
  --storage /Volumes/L8T-1-exfat/lume \
  --disk-size 100GB \
  --unattended sequoia
```

**Note**: VM was later renamed to "mimi" and moved to home storage.

---

## SSH Access

### Enabling SSH
The `--unattended sequoia` preset does NOT automatically enable SSH (unlike `tahoe` preset).

**Manual steps required**:
1. Connect via VNC to the VM
2. Open System Settings → General → Sharing
3. Enable "Remote Login"
4. Ensure user has access

### Connecting to VM
```bash
# Start the VM (now in home storage)
lume run mimi

# Check status
lume get mimi

# SSH into VM
lume ssh mimi

# Run remote commands
lume ssh mimi -- "command here"

# Stop the VM
lume stop mimi
```

**Note**: Since the VM is now in home storage (default), the `--storage` flag is no longer needed.

---

## Installed Development Tools

### 1. Git
- **Version**: 2.50.1 (Apple Git-155)
- **Installed via**: macOS Command Line Developer Tools
- **Installation time**: ~15 hours (triggered automatically when git was first checked)
- **Verification**: `git --version`

### 2. Node.js
- **Version**: v22.12.0
- **Installation method**: Manual download (no sudo required)
- **Location**: `~/.local/node/`
- **Installation commands**:
```bash
curl -fsSL https://nodejs.org/dist/v22.12.0/node-v22.12.0-darwin-arm64.tar.gz -o /tmp/node-v22.tar.gz
cd /tmp && tar -xzf node-v22.tar.gz
mkdir -p ~/.local && mv node-v22.12.0-darwin-arm64 ~/.local/node
echo 'export PATH="$HOME/.local/node/bin:$PATH"' >> ~/.zshrc
```
- **Note**: Initially installed v20.11.0, then upgraded to v22.12.0 for OpenClaw compatibility

### 3. Bun
- **Version**: 1.3.9
- **Installation method**: Official installer script
- **Location**: `~/.bun/`
- **Installation commands**:
```bash
curl -fsSL https://bun.sh/install | bash
```
- **PATH**: Automatically added to `~/.zshrc`
- **Binaries**: `bun`, `bunx`

### 4. OpenClaw
- **Version**: 2026.2.12
- **Installation method**: `bun install -g openclaw`
- **Requirements**: Node.js >= 22.12.0
- **Package count**: 630 packages installed
- **Installation command**:
```bash
export PATH="$HOME/.local/node/bin:$HOME/.bun/bin:$PATH"
bun install -g openclaw
```
- **Verification**: `openclaw --version`

### 5. Homebrew
- **Version**: >=4.3.0
- **Installation method**: User directory install (no sudo)
- **Location**: `~/.homebrew/`
- **Installation commands**:
```bash
mkdir -p ~/.homebrew
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C ~/.homebrew
echo 'export PATH="$HOME/.homebrew/bin:$PATH"' >> ~/.zshrc
```
- **Note**: Installed to user directory to avoid sudo requirements
- **Limitation**: Shows "shallow or no git repository" warning (cosmetic only)

---

## Environment Configuration

### Shell: zsh
Default shell for macOS user `lume`

### PATH Configuration in `~/.zshrc`
```bash
# Node.js
export PATH="$HOME/.local/node/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Homebrew
export PATH="$HOME/.homebrew/bin:$PATH"
```

### Complete Verification Command
```bash
source ~/.zshrc
git --version && node --version && bun --version && openclaw --version && brew --version
```

---

## Important Learnings

### 1. Sequoia vs Tahoe Presets
- **`--unattended sequoia`**: Does NOT enable SSH automatically
- **`--unattended tahoe`**: Creates user `lume` with password `lume` and enables SSH
- **Recommendation**: If SSH is required from the start, use `tahoe` preset

### 2. Command Line Developer Tools
- Automatically triggered when checking for git
- Takes approximately 15 hours to install
- Includes: git, compilers, build tools
- **Tip**: Wait for completion before attempting builds requiring native compilation

### 3. Sudo Access Workarounds
- User `lume` is in `admin` group but password unknown for `sequoia` preset
- Solution: Install tools to user directories (`~/.local/`, `~/.homebrew/`, etc.)
- No sudo required for: Node.js manual install, Homebrew user install, Bun install

### 4. Background Processes
- Long-running installations should use background execution with logging:
```bash
nohup bash -c 'command > /tmp/install.log 2>&1' &
# Check progress
cat /tmp/install.log
```

### 5. Storage Location
- VM originally created on external drive `/Volumes/L8T-1-exfat/lume`
- VM was later moved to "home" storage (default lume location)
- When using home storage, no `--storage` flag is needed
- Default storage is "home" location if not specified

---

## Troubleshooting

### SSH Not Working
**Symptom**: `lume ssh mimi` shows "SSH is not available on VM"  
**Solution**: Manually enable Remote Login in System Settings → Sharing via VNC

### Tool Not Found After Install
**Symptom**: Command not found after installation  
**Solution**: 
1. Check if binary exists: `ls -la ~/.bun/bin/` or `ls -la ~/.local/node/bin/`
2. Reload shell: `source ~/.zshrc`
3. Verify PATH: `echo $PATH`

### Homebrew Needs Sudo
**Symptom**: Homebrew install fails with "Need sudo access"  
**Solution**: Install to user directory (`~/.homebrew/`) instead of system location

### OpenClaw Requires Newer Node
**Symptom**: "openclaw requires Node >=22.12.0"  
**Solution**: Download and install Node v22.12.0+ manually to `~/.local/node/`

---

## Quick Reference Commands

```bash
# Start VM
lume run mimi

# Start VM with shared folder
lume run mimi --shared-dir ~/my-project

# SSH into VM
lume ssh mimi

# Run commands in VM
lume ssh mimi -- "command here"

# Stop VM
lume stop mimi

# Check VM status
lume get mimi

# List all VMs
lume ls

# Delete VM (careful!)
lume delete mimi
```

---

## Next Steps / TODO

- [ ] Configure OpenClaw for your use case
- [ ] Set up shared folders if needed for project work
- [ ] Create a golden image clone for quick resets
- [ ] Test Homebrew package installations
- [ ] Configure git user identity: `git config --global user.name "Name"`
- [ ] Configure git user email: `git config --global user.email "email@example.com"`

---

## Resources

- **Lume Documentation**: https://cua.ai/docs/lume/
- **OpenClaw**: https://openclaw.ai/
- **Lume Sandbox Setup Guide**: https://cua.ai/docs/lume/examples/claude-code/sandbox
- **Node.js Downloads**: https://nodejs.org/en/download
- **Bun Documentation**: https://bun.sh/docs
- **Homebrew Documentation**: https://docs.brew.sh/

---

**Last Updated**: 2026-02-16  
**VM Status**: Running and fully configured ✅  
**Current Disk Usage**: 37.4GB / 100GB
