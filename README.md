# the flake
you need nix.  
see steps in `devenv-nix` repo README owned by this org.  
you need postgres globally, not managed by nix due to permission hell: `brew install postgresql@14`, then `brew services start postgresql@14`. or whatever you use for pkg management if you're like me and are a linux person. figure it out.  

then, init the default db:
`initdb --locale=C -E UTF-8 $(brew --prefix)/var/postgresql@14`

then, `createdb teleband`

then grab the flake from this repo and put it in your Music-CPR-Backend/ clone's root.  
track it. **this is necessary.**  

then run `nix flake update && nix develop`

you'll be met with commands to proceed.  
Here's what you'll see:

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
  - PostgreSQL must be installed via Homebrew
  - PostgreSQL must be running: brew services start postgresql@14
  - Database must exist: createdb teleband

📝 Quick Start:
  1. Ensure PostgreSQL is running
  2. Run 'musiccpr_init' (first time only)
  3. Run 'backend' and 'frontend' in separate terminals
```