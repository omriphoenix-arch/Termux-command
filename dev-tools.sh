#!/data/data/com.termux/files/usr/bin/bash

# ========================================
# Termux Development Tools Script
# ========================================
# Description: Git helper and development utilities
# Author: Termux Scripts Collection
# Version: 1.0
# ========================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
DEV_TOOLS_DIR="$HOME/.dev-tools"
TEMPLATES_DIR="$DEV_TOOLS_DIR/templates"
CONFIG_FILE="$DEV_TOOLS_DIR/config"

# Functions
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                  TERMUX DEVELOPMENT TOOLS                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

success_message() {
    print_colored "$GREEN" "✅ $1"
}

error_message() {
    print_colored "$RED" "❌ Error: $1"
}

warning_message() {
    print_colored "$YELLOW" "⚠️  Warning: $1"
}

info_message() {
    print_colored "$BLUE" "ℹ️  $1"
}

check_git_repo() {
    if [ ! -d ".git" ]; then
        error_message "Not a git repository. Please run this command in a git repository."
        return 1
    fi
    return 0
}

setup_dev_environment() {
    print_colored "$BLUE" "🔧 Setting up development environment..."
    
    # Create directories
    mkdir -p "$DEV_TOOLS_DIR" "$TEMPLATES_DIR"
    
    # Install essential development packages
    local packages=(
        "git"
        "nodejs"
        "python"
        "clang"
        "make"
        "cmake"
        "vim"
        "nano"
        "curl"
        "wget"
        "openssh"
        "rsync"
    )
    
    print_colored "$CYAN" "Installing essential packages..."
    for pkg in "${packages[@]}"; do
        if ! pkg list-installed 2>/dev/null | grep -q "^$pkg/"; then
            print_colored "$YELLOW" "Installing $pkg..."
            pkg install -y "$pkg" 2>/dev/null
        else
            print_colored "$GREEN" "$pkg already installed"
        fi
    done
    
    # Setup Git if not configured
    if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
        print_colored "$CYAN" "🔑 Git Configuration Setup"
        echo -n "Enter your name: "
        read -r git_name
        echo -n "Enter your email: "
        read -r git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        success_message "Git configured with name: $git_name, email: $git_email"
    fi
    
    # Setup SSH key if not exists
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        print_colored "$CYAN" "🔐 SSH Key Generation"
        echo -n "Generate SSH key? (y/N): "
        read -r generate_ssh
        
        if [[ "$generate_ssh" =~ ^[Yy]$ ]]; then
            ssh-keygen -t rsa -b 4096 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_rsa" -N ""
            success_message "SSH key generated at ~/.ssh/id_rsa"
            print_colored "$CYAN" "Public key:"
            cat "$HOME/.ssh/id_rsa.pub"
        fi
    fi
    
    success_message "Development environment setup complete!"
}

git_status_enhanced() {
    check_git_repo || return 1
    
    print_colored "$WHITE" "📊 Enhanced Git Status"
    echo "────────────────────────────────────────────────────────────"
    
    # Basic status
    echo -e "${CYAN}Repository:${NC} $(basename "$(git rev-parse --show-toplevel)")"
    echo -e "${CYAN}Branch:${NC}     $(git branch --show-current)"
    echo -e "${CYAN}Remote:${NC}     $(git remote get-url origin 2>/dev/null || echo "No remote")"
    echo
    
    # File status
    local status_output=$(git status --porcelain)
    if [ -n "$status_output" ]; then
        print_colored "$YELLOW" "📝 Changes:"
        while IFS= read -r line; do
            local status="${line:0:2}"
            local file="${line:3}"
            
            case "$status" in
                "M ") echo -e "  ${GREEN}Modified:${NC}   $file" ;;
                " M") echo -e "  ${YELLOW}Modified:${NC}   $file (unstaged)" ;;
                "A ") echo -e "  ${GREEN}Added:${NC}      $file" ;;
                "D ") echo -e "  ${RED}Deleted:${NC}    $file" ;;
                "??") echo -e "  ${BLUE}Untracked:${NC}  $file" ;;
                "R ") echo -e "  ${PURPLE}Renamed:${NC}    $file" ;;
                *) echo -e "  ${WHITE}$status${NC}       $file" ;;
            esac
        done <<< "$status_output"
    else
        success_message "Working directory clean"
    fi
    
    echo
    # Recent commits
    print_colored "$CYAN" "📚 Recent Commits:"
    git log --oneline -5 --color=always
    
    echo
    # Branch information
    local ahead=$(git rev-list --count @{u}.. 2>/dev/null || echo "0")
    local behind=$(git rev-list --count ..@{u} 2>/dev/null || echo "0")
    
    if [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        print_colored "$YELLOW" "🔄 Sync Status:"
        [ "$ahead" -gt 0 ] && echo -e "  ${GREEN}Ahead:${NC}  $ahead commits"
        [ "$behind" -gt 0 ] && echo -e "  ${RED}Behind:${NC} $behind commits"
    else
        success_message "Branch is up to date"
    fi
}

git_quick_commit() {
    check_git_repo || return 1
    
    print_colored "$BLUE" "⚡ Quick Git Commit"
    
    # Show current status
    git status --short
    echo
    
    # Ask for commit message
    echo -n "Enter commit message: "
    read -r commit_msg
    
    if [ -z "$commit_msg" ]; then
        error_message "Commit message cannot be empty"
        return 1
    fi
    
    # Add all changes
    git add .
    
    # Commit
    if git commit -m "$commit_msg"; then
        success_message "Changes committed successfully"
        
        # Ask to push
        echo -n "Push to remote? (y/N): "
        read -r push_confirm
        
        if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
            if git push; then
                success_message "Changes pushed to remote"
            else
                error_message "Failed to push changes"
            fi
        fi
    else
        error_message "Failed to commit changes"
    fi
}

create_gitignore() {
    local project_type=""
    
    print_colored "$BLUE" "📝 Create .gitignore"
    echo
    echo "Select project type:"
    echo "1. Python"
    echo "2. Node.js"
    echo "3. C/C++"
    echo "4. Java"
    echo "5. General"
    echo "6. Custom"
    
    echo -n "Choose (1-6): "
    read -r choice
    
    case $choice in
        1)
            cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
            success_message "Python .gitignore created"
            ;;
        2)
            cat > .gitignore << 'EOF'
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.npm
.yarn-integrity

# Build outputs
dist/
build/
*.tgz
*.tar.gz

# Environment
.env
.env.local
.env.production

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
            success_message "Node.js .gitignore created"
            ;;
        3)
            cat > .gitignore << 'EOF'
# C/C++
*.o
*.obj
*.exe
*.dll
*.so
*.dylib
*.a
*.lib

# Build directories
build/
debug/
release/
obj/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
            success_message "C/C++ .gitignore created"
            ;;
        4)
            cat > .gitignore << 'EOF'
# Java
*.class
*.jar
*.war
*.ear
*.aar

# Build tools
target/
build/
.gradle/

# IDE
.idea/
.eclipse/
*.iml
*.ipr
*.iws

# OS
.DS_Store
Thumbs.db
EOF
            success_message "Java .gitignore created"
            ;;
        5)
            cat > .gitignore << 'EOF'
# General
*.log
*.tmp
*.temp
*~
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build
build/
dist/
*.o
*.obj
EOF
            success_message "General .gitignore created"
            ;;
        6)
            print_colored "$CYAN" "Enter patterns to ignore (one per line, empty line to finish):"
            cat > .gitignore << 'EOF'
# Custom .gitignore
EOF
            while true; do
                echo -n "Pattern: "
                read -r pattern
                [ -z "$pattern" ] && break
                echo "$pattern" >> .gitignore
            done
            success_message "Custom .gitignore created"
            ;;
    esac
}

project_initializer() {
    print_colored "$BLUE" "🚀 Project Initializer"
    echo
    
    echo -n "Enter project name: "
    read -r project_name
    
    if [ -z "$project_name" ]; then
        error_message "Project name cannot be empty"
        return 1
    fi
    
    # Create project directory
    mkdir -p "$project_name"
    cd "$project_name" || return 1
    
    # Initialize git
    git init
    success_message "Git repository initialized"
    
    # Create basic structure
    echo "Select project type:"
    echo "1. Python Project"
    echo "2. Node.js Project"
    echo "3. C/C++ Project"
    echo "4. Shell Script Project"
    echo "5. Basic Project"
    
    echo -n "Choose (1-5): "
    read -r proj_type
    
    case $proj_type in
        1)
            mkdir -p src tests docs
            touch src/__init__.py src/main.py tests/test_main.py
            echo "# $project_name" > README.md
            echo "requirements.txt" > requirements.txt
            create_gitignore <<< "1"
            success_message "Python project structure created"
            ;;
        2)
            mkdir -p src tests docs
            touch src/index.js tests/test.js
            echo "# $project_name" > README.md
            npm init -y
            create_gitignore <<< "2"
            success_message "Node.js project structure created"
            ;;
        3)
            mkdir -p src include build tests docs
            touch src/main.c include/main.h
            echo "# $project_name" > README.md
            cat > Makefile << 'EOF'
CC=gcc
CFLAGS=-Wall -Wextra -std=c99
SRCDIR=src
INCDIR=include
BUILDDIR=build

SOURCES=$(wildcard $(SRCDIR)/*.c)
OBJECTS=$(SOURCES:$(SRCDIR)/%.c=$(BUILDDIR)/%.o)
TARGET=$(BUILDDIR)/main

all: $(TARGET)

$(TARGET): $(OBJECTS) | $(BUILDDIR)
	$(CC) $(OBJECTS) -o $@

$(BUILDDIR)/%.o: $(SRCDIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -I$(INCDIR) -c $< -o $@

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR)

.PHONY: all clean
EOF
            create_gitignore <<< "3"
            success_message "C/C++ project structure created"
            ;;
        4)
            mkdir -p scripts tests docs
            touch scripts/main.sh tests/test.sh
            chmod +x scripts/main.sh tests/test.sh
            echo "# $project_name" > README.md
            create_gitignore <<< "5"
            success_message "Shell script project structure created"
            ;;
        5)
            mkdir -p docs
            touch main.txt
            echo "# $project_name" > README.md
            create_gitignore <<< "5"
            success_message "Basic project structure created"
            ;;
    esac
    
    # Initial commit
    git add .
    git commit -m "Initial commit: $project_name project setup"
    
    success_message "Project '$project_name' created and initialized!"
    print_colored "$CYAN" "Project location: $(pwd)"
}

code_formatter() {
    print_colored "$BLUE" "🎨 Code Formatter"
    echo
    
    echo "Select formatter:"
    echo "1. Python (autopep8)"
    echo "2. JavaScript/JSON (prettier)"
    echo "3. C/C++ (clang-format)"
    echo "4. Shell Script (shfmt)"
    
    echo -n "Choose (1-4): "
    read -r formatter_choice
    
    case $formatter_choice in
        1)
            if ! command -v autopep8 &> /dev/null; then
                print_colored "$YELLOW" "Installing autopep8..."
                pip install autopep8
            fi
            
            find . -name "*.py" -exec autopep8 --in-place --aggressive --aggressive {} \;
            success_message "Python files formatted"
            ;;
        2)
            if ! command -v prettier &> /dev/null; then
                print_colored "$YELLOW" "Installing prettier..."
                npm install -g prettier
            fi
            
            prettier --write "**/*.{js,json,css,html,md}"
            success_message "JavaScript/JSON files formatted"
            ;;
        3)
            if ! command -v clang-format &> /dev/null; then
                print_colored "$YELLOW" "Installing clang-format..."
                pkg install clang
            fi
            
            find . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs clang-format -i
            success_message "C/C++ files formatted"
            ;;
        4)
            if ! command -v shfmt &> /dev/null; then
                warning_message "shfmt not available. Using basic formatting..."
                find . -name "*.sh" -exec bash -c 'expand -t 4 "$1" | sponge "$1"' _ {} \;
            else
                find . -name "*.sh" -exec shfmt -w {} \;
            fi
            success_message "Shell scripts formatted"
            ;;
    esac
}

dependency_manager() {
    print_colored "$BLUE" "📦 Dependency Manager"
    echo
    
    if [ -f "package.json" ]; then
        print_colored "$CYAN" "Node.js project detected"
        echo "1. Install dependencies (npm install)"
        echo "2. Add dependency (npm install <package>)"
        echo "3. Update dependencies (npm update)"
        echo "4. Audit dependencies (npm audit)"
        
        echo -n "Choose (1-4): "
        read -r npm_choice
        
        case $npm_choice in
            1) npm install ;;
            2) 
                echo -n "Package name: "
                read -r pkg_name
                npm install "$pkg_name"
                ;;
            3) npm update ;;
            4) npm audit ;;
        esac
        
    elif [ -f "requirements.txt" ]; then
        print_colored "$CYAN" "Python project detected"
        echo "1. Install requirements (pip install -r requirements.txt)"
        echo "2. Generate requirements (pip freeze > requirements.txt)"
        echo "3. Create virtual environment"
        echo "4. Activate virtual environment"
        
        echo -n "Choose (1-4): "
        read -r pip_choice
        
        case $pip_choice in
            1) pip install -r requirements.txt ;;
            2) pip freeze > requirements.txt ;;
            3) 
                echo -n "Virtual environment name: "
                read -r venv_name
                python -m venv "$venv_name"
                success_message "Virtual environment '$venv_name' created"
                ;;
            4) 
                if [ -d "venv" ]; then
                    source venv/bin/activate
                    success_message "Virtual environment activated"
                else
                    error_message "No 'venv' directory found"
                fi
                ;;
        esac
        
    else
        warning_message "No package manager files found (package.json, requirements.txt)"
    fi
}

show_help() {
    cat << EOF
Termux Development Tools v1.0

Usage: $0 [COMMAND]

COMMANDS:
    setup               Setup development environment
    status              Enhanced git status
    commit              Quick git commit
    init                Initialize new project
    gitignore           Create .gitignore file
    format              Format code files
    deps                Manage dependencies
    
Examples:
    $0 setup            # Setup dev environment
    $0 status           # Show git status
    $0 commit           # Quick commit
    $0 init             # Create new project

EOF
}

main_menu() {
    print_banner
    
    echo -e "${WHITE}Development Tools Menu:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo -e "${CYAN}1.${NC} Setup Development Environment"
    echo -e "${CYAN}2.${NC} Enhanced Git Status"
    echo -e "${CYAN}3.${NC} Quick Git Commit"
    echo -e "${CYAN}4.${NC} Initialize New Project"
    echo -e "${CYAN}5.${NC} Create .gitignore"
    echo -e "${CYAN}6.${NC} Code Formatter"
    echo -e "${CYAN}7.${NC} Dependency Manager"
    echo -e "${CYAN}8.${NC} Exit"
    echo
    
    echo -n "Choose option (1-8): "
    read -r choice
    
    case $choice in
        1) setup_dev_environment ;;
        2) git_status_enhanced ;;
        3) git_quick_commit ;;
        4) project_initializer ;;
        5) create_gitignore ;;
        6) code_formatter ;;
        7) dependency_manager ;;
        8) 
            print_colored "$YELLOW" "👋 Goodbye!"
            exit 0
            ;;
        *)
            error_message "Invalid option"
            ;;
    esac
    
    echo
    print_colored "$CYAN" "Press any key to continue..."
    read -n 1 -s
    main_menu
}

# Main script logic
case "${1:-}" in
    setup) setup_dev_environment ;;
    status) git_status_enhanced ;;
    commit) git_quick_commit ;;
    init) project_initializer ;;
    gitignore) create_gitignore ;;
    format) code_formatter ;;
    deps) dependency_manager ;;
    -h|--help) show_help ;;
    *) main_menu ;;
esac