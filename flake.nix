{
  description = "MusicCPR Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Use Python 3.12 as specified in the guide
        python = pkgs.python312;
        
        # Create a Python environment with essential packages
        pythonEnv = python.withPackages (ps: with ps; [
          pip
          virtualenv
          setuptools
          wheel
        ]);
        
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python environment
            pythonEnv
            
            # Node.js 22
            nodejs_22
            
            # Build dependencies from the guide
            openssl
            readline
            sqlite
            xz
            zlib
            tcl
            tk
            
            # Git
            git
            
            # Build tools
            gcc
            gnumake
            pkg-config
            
            # PostgreSQL client tools (will use system PostgreSQL if available)
            postgresql_14
          ];
          
          # Environment variables
          shellHook = ''
            # Platform detection
            detect_platform() {
              if [ -f /proc/version ] && grep -q Microsoft /proc/version; then
                echo "wsl"
              elif [ "$(uname)" = "Darwin" ]; then
                echo "macos"
              elif [ "$(uname)" = "Linux" ]; then
                echo "linux"
              else
                echo "unknown"
              fi
            }
            
            PLATFORM=$(detect_platform)
            
            echo "🎵 MusicCPR Development Environment"
            echo "=================================="
            echo "Platform: $PLATFORM"
            
            # Project root
            PROJECT_ROOT="$PWD"
            
            # Virtual environment setup (following the guide exactly)
            VENV_DIR="$PROJECT_ROOT/../musenv"
            
            # PostgreSQL configuration (Cross-platform)
            export PGHOST="''${PGHOST:-localhost}"
            export PGPORT="''${PGPORT:-5432}"
            export PGDATABASE="''${PGDATABASE:-teleband}"
            export DATABASE_URL="''${DATABASE_URL:-postgres://$(whoami)@localhost/teleband}"
            export DJANGO_SETTINGS_MODULE="config.settings.local"
            
            # Ensure we use the correct Python
            export PYTHON="${pythonEnv}/bin/python3.12"
            
            # Create and activate virtual environment
            setup_venv() {
              echo "Setting up Python virtual environment..."
              
              if [ ! -d "$VENV_DIR" ]; then
                echo "Creating virtual environment at $VENV_DIR"
                $PYTHON -m venv "$VENV_DIR"
              fi
              
              echo "Activating virtual environment..."
              source "$VENV_DIR/bin/activate"
              
              # Clean any Python path pollution
              export PYTHONPATH=""
              unset NIX_PYTHONPATH
              
              # Upgrade pip immediately after activation
              pip install --upgrade pip --quiet
              
              echo "Python: $(which python) - $(python --version)"
              echo "Pip: $(which pip)"
            }
            
            # Check PostgreSQL status (Cross-platform)
            check_postgres() {
              echo "Checking PostgreSQL status..."
              
              # Try to connect to PostgreSQL to check if it's running
              if psql -c '\q' 2>/dev/null; then
                echo "✅ PostgreSQL is running and accessible"
                
                # Check if database exists
                if psql -lqt | cut -d \| -f 1 | grep -qw teleband; then
                  echo "✅ Database 'teleband' exists"
                else
                  echo "⚠️  Database 'teleband' not found"
                  echo "   Run: createdb teleband"
                fi
              else
                echo "❌ PostgreSQL is not running or not accessible"
                echo ""
                echo "   To start PostgreSQL:"
                
                # Platform-specific start commands
                case "$PLATFORM" in
                  "macos")
                    echo "   macOS: brew services start postgresql@14"
                    ;;
                  "linux"|"wsl")
                    if command -v systemctl >/dev/null 2>&1; then
                      echo "   Linux: sudo systemctl start postgresql"
                    elif command -v service >/dev/null 2>&1; then
                      echo "   Linux: sudo service postgresql start"
                    else
                      echo "   Check your system's service manager to start postgresql"
                    fi
                    ;;
                  *)
                    echo "   Check your system's service manager to start postgresql"
                    ;;
                esac
              fi
            }
            
            # Initial setup (run once)
            musiccpr_init() {
              echo "🚀 Running initial MusicCPR setup..."
              echo ""
              
              # Check PostgreSQL first
              check_postgres
              echo ""
              
              # 1. Setup Python environment
              setup_venv
              
              # 2. Create .env file
              echo "Creating .env file..."
              cat > .env << EOF
DATABASE_URL=$DATABASE_URL
DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
SECRET_KEY=your-secret-key-here-$(openssl rand -hex 32)
EOF
              echo "✅ Created .env file"
              
              # 3. Install Python dependencies
              echo ""
              echo "Installing Python dependencies..."
              pip install --upgrade pip
              pip install -r requirements/local.txt
              
              # 4. Create media directories
              mkdir -p teleband/media/accompaniments
              mkdir -p teleband/media/sample_audio
              
              if [ -z "$(ls -A teleband/media/accompaniments 2>/dev/null)" ] || [ -z "$(ls -A teleband/media/sample_audio 2>/dev/null)" ]; then
                echo ""
                echo "⚠️  Media directories are empty!"
                echo "   Please get accompaniments and sample_audio from a teammate"
                echo "   and place them in teleband/media/"
              fi
              
              # 5. Check database and run migrations
              if psql -lqt | cut -d \| -f 1 | grep -qw teleband; then
                echo ""
                echo "Running database migrations..."
                python manage.py migrate
                
                # 6. Create superuser
                echo ""
                echo "Creating Django superuser..."
                echo "This will be your admin login for http://127.0.0.1:8000/admin/"
                python manage.py createsuperuser
              else
                echo ""
                echo "⚠️  Database 'teleband' not found!"
                echo "   Please create it with: createdb teleband"
                echo "   Then run 'musiccpr_init' again"
                return 1
              fi
              
              # 7. Setup frontend
              if [ -d ../CPR-Music ]; then
                echo ""
                echo "Setting up frontend..."
                cd ../CPR-Music
                
                if [ ! -f .env.local ]; then
                  cat > .env.local << EOF
SECRET=idkjustpleasehavesomethingfortesting
NEXTAUTH_URL="http://localhost:3000"
EOF
                fi
                
                echo "Installing frontend dependencies..."
                npm install
                
                # Update browserslist database
                npx update-browserslist-db@latest --yes 2>/dev/null || true
                
                cd "$PROJECT_ROOT"
              else
                echo ""
                echo "⚠️  Frontend directory ../CPR-Music not found!"
                echo "   Please clone it from your fork"
              fi
              
              echo ""
              echo "✅ Initial setup complete!"
              echo ""
              echo "To start development:"
              echo "  1. Run 'backend' to start Django"
              echo "  2. Run 'frontend' in another terminal to start Next.js"
            }
            
            # Daily startup
            musiccpr_start() {
              echo "🎸 Starting MusicCPR development environment..."
              
              # Check PostgreSQL
              check_postgres
              
              # Activate virtual environment
              setup_venv
              
              # Check for migrations
              if [ -f manage.py ] && psql -lqt | cut -d \| -f 1 | grep -qw teleband; then
                echo ""
                echo "Checking for unapplied migrations..."
                if python manage.py showmigrations | grep -q "\[ \]"; then
                  echo "Found unapplied migrations. Applying..."
                  python manage.py migrate
                else
                  echo "All migrations are up to date ✓"
                fi
              fi
              
              echo ""
              echo "✅ Environment ready!"
              echo ""
              echo "Commands:"
              echo "  backend  - Start Django server"
              echo "  frontend - Start Next.js server"
              echo ""
              echo "URLs:"
              echo "  Django Admin: http://127.0.0.1:8000/admin/"
              echo "  Frontend:     http://localhost:3000"
            }
            
            # Start backend
            backend() {
              if [ ! -f "$VENV_DIR/bin/activate" ]; then
                echo "Virtual environment not found. Run 'musiccpr_init' first!"
                return 1
              fi
              
              source "$VENV_DIR/bin/activate"
              
              echo "Starting Django development server..."
              python manage.py runserver
            }
            
            # Start frontend
            frontend() {
              if [ ! -d ../CPR-Music ]; then
                echo "Frontend directory not found at ../CPR-Music"
                return 1
              fi
              
              cd ../CPR-Music
              echo "Starting Next.js development server..."
              npm run dev
            }
            
            # Status check
            musiccpr_status() {
              echo "🔍 MusicCPR Environment Status"
              echo "=============================="
              echo ""
              
              # Python/venv status
              echo "Python Environment:"
              if [ -d "$VENV_DIR" ]; then
                echo "  ✅ Virtual environment exists"
                if [ -n "$VIRTUAL_ENV" ]; then
                  echo "  ✅ Virtual environment is activated"
                else
                  echo "  ⚠️  Virtual environment not activated"
                fi
              else
                echo "  ❌ Virtual environment not found"
              fi
              echo ""
              
              # PostgreSQL status
              echo "PostgreSQL:"
              check_postgres
              echo ""
              
              # Django status
              echo "Django Project:"
              if [ -f manage.py ]; then
                echo "  ✅ In Django project directory"
                if [ -f .env ]; then
                  echo "  ✅ .env file exists"
                else
                  echo "  ❌ .env file missing"
                fi
              else
                echo "  ❌ Not in Django project directory"
              fi
              echo ""
              
              # Frontend status
              echo "Frontend:"
              if [ -d ../CPR-Music ]; then
                echo "  ✅ Frontend directory found"
                if [ -f ../CPR-Music/.env.local ]; then
                  echo "  ✅ Frontend .env.local exists"
                else
                  echo "  ❌ Frontend .env.local missing"
                fi
              else
                echo "  ❌ Frontend directory not found"
              fi
              echo ""
              
              # Media directories
              echo "Media Directories:"
              if [ -d teleband/media/accompaniments ] && [ -n "$(ls -A teleband/media/accompaniments 2>/dev/null)" ]; then
                echo "  ✅ Accompaniments folder has content"
              else
                echo "  ⚠️  Accompaniments folder is empty"
              fi
              
              if [ -d teleband/media/sample_audio ] && [ -n "$(ls -A teleband/media/sample_audio 2>/dev/null)" ]; then
                echo "  ✅ Sample audio folder has content"
              else
                echo "  ⚠️  Sample audio folder is empty"
              fi
            }
            
            # Help command
            mhelp() {
              echo "🎵 MusicCPR Development Environment Help"
              echo "======================================="
              echo ""
              echo "📚 Available Commands:"
              echo ""
              echo "  mhelp            - Show this help message"
              echo "  musiccpr_init    - First-time setup (venv, deps, database, superuser)"
              echo "  musiccpr_start   - Daily startup (activate venv, check migrations)"
              echo "  musiccpr_status  - Check environment status"
              echo ""
              echo "🚀 Running Services:"
              echo "  backend          - Start Django server"
              echo "  frontend         - Start Next.js server (run in new terminal)"
              echo ""
              echo "📍 Project URLs:"
              echo "  Django Admin: http://127.0.0.1:8000/admin/"
              echo "  Frontend:     http://localhost:3000"
              echo ""
              echo "⚠️  Prerequisites:"
              echo "  - PostgreSQL must be installed and running"
              echo "  - Database 'teleband' must exist and be accessible by your user"
              echo "  - See README.md for platform-specific PostgreSQL setup"
              echo ""
              echo "📝 Quick Start:"
              echo "  1. Ensure PostgreSQL is running"
              echo "  2. Run 'musiccpr_init' (first time only)"
              echo "  3. Run 'backend' and 'frontend' in separate terminals"
            }
            
            # Auto-activate venv if it exists
            if [ -d "$VENV_DIR" ]; then
              setup_venv
            fi
            
            echo ""
            echo "Node: $(node --version)"
            echo "PostgreSQL client: $(psql --version)"
            echo ""
            echo "Type 'mhelp' for help"
            echo ""
            
            if [ ! -d "$VENV_DIR" ]; then
              echo "👉 First time? Make sure PostgreSQL is running, then run 'musiccpr_init'"
            else
              echo "👉 Run 'musiccpr_start' to begin development"
            fi
          '';
        };
      });
}