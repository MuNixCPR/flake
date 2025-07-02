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
            
            # PostgreSQL 14
            postgresql_14
            
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
            
            # Development tools
            pgcli  # Alternative to pgAdmin4
          ];
          
          # Environment variables
          shellHook = ''
            echo "🎵 MusicCPR Development Environment"
            echo "=================================="
            
            # Project root
            PROJECT_ROOT="$PWD"
            
            # Virtual environment setup (following the guide exactly)
            VENV_DIR="$PROJECT_ROOT/../musenv"
            
            # PostgreSQL setup
            export PGDATA="$PROJECT_ROOT/.postgres"
            export PGHOST="localhost"
            export PGPORT="5432"
            export PGDATABASE="teleband"
            
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
              
              echo "Python: $(which python) - $(python --version)"
            }
            
            # Setup PostgreSQL
            setup_postgres() {
              if [ ! -d "$PGDATA" ]; then
                echo "Initializing PostgreSQL..."
                initdb --auth=trust --no-locale --encoding=UTF8
              fi
              
              if ! pg_ctl status > /dev/null 2>&1; then
                echo "Starting PostgreSQL..."
                pg_ctl start -l "$PGDATA/postgres.log"
                
                # Wait for PostgreSQL to start
                sleep 2
              else
                echo "PostgreSQL is already running"
              fi
              
              # Always check if database exists and create if needed
              if ! psql -lqt | cut -d \| -f 1 | grep -qw teleband; then
                echo "Creating teleband database..."
                createdb teleband
              else
                echo "Database 'teleband' already exists"
              fi
            }
            
            # Initial setup (run once)
            musiccpr_init() {
              echo "🚀 Running initial MusicCPR setup..."
              
              # 1. Setup Python environment
              setup_venv
              
              # 2. Setup PostgreSQL
              setup_postgres
              
              # 3. Create .env file
              echo "Creating .env file..."
              cat > .env << EOF
DATABASE_URL=postgres:///teleband
DJANGO_SETTINGS_MODULE=config.settings.local
EOF
              
              # 4. Install Python dependencies
              echo "Installing Python dependencies..."
              pip install --upgrade pip
              pip install -r requirements/local.txt
              
              # 5. Create media directories
              mkdir -p teleband/media/accompaniments
              mkdir -p teleband/media/sample_audio
              echo "⚠️  Don't forget to get accompaniments and sample_audio from a teammate!"
              
              # 6. Run migrations
              echo "Running database migrations..."
              python manage.py migrate
              
              # 7. Create superuser
              echo "Creating Django superuser..."
              python manage.py createsuperuser
              
              # 8. Setup frontend
              if [ -d ../CPR-Music ]; then
                echo "Setting up frontend..."
                cd ../CPR-Music
                
                if [ ! -f .env.local ]; then
                  cat > .env.local << EOF
SECRET=idkjustpleasehavesomethingfortesting
NEXTAUTH_URL="http://localhost:3000"
EOF
                fi
                
                npm install
                cd "$PROJECT_ROOT"
              else
                echo "⚠️  Frontend directory ../CPR-Music not found!"
              fi
              
              echo "✅ Initial setup complete!"
              echo ""
              echo "To start development:"
              echo "  1. Run 'musiccpr_start' to start both backend and frontend"
              echo "  2. Or run 'start_backend' and 'start_frontend' separately"
            }
            
            # Daily startup command
            musiccpr_start() {
              echo "🎸 Starting MusicCPR development environment..."
              
              # Activate virtual environment
              setup_venv
              
              # Start PostgreSQL if needed
              setup_postgres
              
              echo ""
              echo "✅ Environment ready!"
              echo ""
              echo "Start the backend with: start_backend"
              echo "Start the frontend with: start_frontend (in a new terminal)"
              echo ""
              echo "URLs:"
              echo "  Backend: http://127.0.0.1:8000/admin/"
              echo "  Frontend: http://localhost:3000"
            }
            
            # Helper functions
            start_backend() {
              if [ ! -f "$VENV_DIR/bin/activate" ]; then
                echo "Virtual environment not found. Run 'musiccpr_init' first!"
                return 1
              fi
              
              source "$VENV_DIR/bin/activate"
              python manage.py runserver
            }
            
            start_frontend() {
              cd ../CPR-Music
              npm run dev
            }
            
            stop_postgres() {
              pg_ctl stop
            }
            
            # Auto-activate venv if it exists
            if [ -d "$VENV_DIR" ]; then
              setup_venv
            fi
            
            echo ""
            echo "Available commands:"
            echo "  musiccpr_init   - First-time setup (creates venv, installs deps, etc.)"
            echo "  musiccpr_start  - Daily startup (activates venv, starts postgres)"
            echo "  start_backend   - Start Django development server"
            echo "  start_frontend  - Start Next.js frontend"
            echo "  stop_postgres   - Stop PostgreSQL"
            echo ""
            
            if [ ! -d "$VENV_DIR" ]; then
              echo "👉 First time? Run 'musiccpr_init' to set everything up!"
            else
              echo "👉 Run 'musiccpr_start' to begin development!"
            fi
          '';
        };
      });
}