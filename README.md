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

## Install PostgreSQL

Install PostgreSQL with your package manager of choice and start the service:

**Arch Linux (paru/yay/pacman):**
```bash
# Install
paru -S postgresql
# or: yay -S postgresql
# or: sudo pacman -S postgresql

# Initialize database
sudo -u postgres initdb -D /var/lib/postgres/data

# Start and enable service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create your user and database
sudo -u postgres createuser --interactive $(whoami)
sudo -u postgres createdb teleband -O $(whoami)
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres createuser --interactive $(whoami)
sudo -u postgres createdb teleband -O $(whoami)
```

**macOS (Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
initdb --locale=C -E UTF-8 $(brew --prefix)/var/postgresql@14
createdb teleband
```

**Other Linux distros:** Install postgres with your package manager of choice, then start the service and create the database as shown above.

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