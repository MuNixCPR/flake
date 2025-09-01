# MusicCPR Development Environment with Nix

## Install Nix

For Linux users (including Arch Linux):

**Bash/Zsh:**
```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

**Fish shell:**
```fish
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

For macOS users, see the [official Nix installation guide](https://nixos.org/download).

**If you get "File already exists" errors:** You likely have Nix already installed. Instead of reinstalling, just activate it in your current shell:

```fish
# For fish shell users
set -U fish_user_paths /nix/var/nix/profiles/default/bin $fish_user_paths
```

```bash
# For bash/zsh users  
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Then verify with: `nix --version`

## Configure Nix Experimental Features

Flakes require experimental features to be enabled. Choose one option:

**Option 1 - Enable permanently (recommended):**
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**Option 2 - Use flags each time:**
```bash
nix --extra-experimental-features "nix-command flakes" flake update
nix --extra-experimental-features "nix-command flakes" develop
```

## Install PostgreSQL

Install PostgreSQL with your package manager of choice:

**Arch Linux (paru/yay/pacman):**
```bash
paru -S postgresql
# or: yay -S postgresql  
# or: sudo pacman -S postgresql
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

**macOS (Homebrew):**
```bash
brew install postgresql@14
```

**Other Linux distros:** Install postgres with your package manager of choice.

## Database Setup

After installing PostgreSQL, you need to initialize and configure the database:

### Linux Users (Arch, Ubuntu, etc.)

1. **Initialize the database cluster:**
   ```bash
   # Arch Linux
   sudo -u postgres initdb -D /var/lib/postgres/data
   
   # Ubuntu/Debian (usually auto-initialized during install)
   # Skip this step if /var/lib/postgresql/14/main already exists
   ```

2. **Start and enable PostgreSQL service:**
   ```bash
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

3. **Create your database user:**
   ```bash
   sudo -u postgres createuser --interactive $(whoami)
   # When prompted, choose:
   # - Shall the new role be a superuser? (y/n) y
   ```

4. **Create the teleband database:**
   ```bash
   sudo -u postgres createdb teleband -O $(whoami)
   ```

### macOS Users (Homebrew)

1. **Start PostgreSQL service:**
   ```bash
   brew services start postgresql@14
   ```

2. **Initialize database (if needed):**
   ```bash
   initdb --locale=C -E UTF-8 $(brew --prefix)/var/postgresql@14
   ```

3. **Create the teleband database:**
   ```bash
   createdb teleband
   ```

### Verify Database Setup

Test your database connection:
```bash
psql -d teleband -c "SELECT version();"
```

If successful, you should see PostgreSQL version information.

## Setup Development Environment

1. Clone your MusicCPR backend repository
2. Copy `flake.nix` from this repo to your `Music-CPR-Backend/` clone's root directory
3. Track the flake file with git (**this is necessary**)
4. Update and enter the nix development shell:

```bash
cd Music-CPR-Backend/
nix flake update && nix develop
```

Once in the nix shell, you'll see the help menu with available commands:

```
🎵 MusicCPR Development Environment Help
=======================================

📚 Available Commands:

  mhelp            - Show this help message
  musiccpr_init    - First-time setup (venv, deps, database, superuser)
  musiccpr_start   - Daily startup (activate venv, check migrations)
  musiccpr_status  - Check environment status

🚀 Running Services:
  backend          - Start Django server
  frontend         - Start Next.js server (run in new terminal)

📍 Project URLs:
  Django Admin: http://127.0.0.1:8000/admin/
  Frontend:     http://localhost:3000

⚠️  Prerequisites:
  - PostgreSQL must be installed and running (see PostgreSQL setup above)
  - Database 'teleband' must exist and be accessible by your user

📝 Quick Start:
  1. Ensure PostgreSQL is running
  2. Run 'musiccpr_init' (first time only)
  3. Run 'backend' and 'frontend' in separate terminals
```