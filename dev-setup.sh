#!/data/data/com.termux/files/usr/bin/bash
# Development Environment Setup Script

echo "💻 TERMUX DEVELOPMENT SETUP"
echo "============================"

# Check if essentials are installed
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Git not found. Please run install-essentials.sh first!"
    exit 1
fi

echo ""
echo "🔧 Setting up development environment..."

# Git configuration
echo ""
echo "📝 Git Configuration:"
read -p "Enter your Git username: " git_username
read -p "Enter your Git email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global init.defaultBranch main
git config --global pull.rebase false

echo "✅ Git configured successfully!"

# Python development setup
echo ""
read -p "🐍 Set up Python development environment? (y/n): " setup_python
if [[ $setup_python =~ ^[Yy]$ ]]; then
    echo "Installing Python development tools..."
    
    # Install Python if not present
    if ! command -v python >/dev/null 2>&1; then
        pkg install -y python python-pip
    fi
    
    # Install common Python packages
    pip install --upgrade pip
    pip install --user \
        requests \
        beautifulsoup4 \
        lxml \
        pillow \
        matplotlib \
        numpy \
        pandas \
        jupyter \
        flask \
        fastapi \
        pytest \
        black \
        flake8 \
        virtualenv
    
    echo "✅ Python development environment ready!"
fi

# Node.js development setup
echo ""
read -p "📦 Set up Node.js development environment? (y/n): " setup_node
if [[ $setup_node =~ ^[Yy]$ ]]; then
    echo "Installing Node.js development tools..."
    
    # Install Node.js if not present
    if ! command -v node >/dev/null 2>&1; then
        pkg install -y nodejs npm
    fi
    
    # Install global packages
    npm install -g \
        express-generator \
        create-react-app \
        @vue/cli \
        typescript \
        ts-node \
        nodemon \
        eslint \
        prettier \
        http-server \
        live-server
    
    echo "✅ Node.js development environment ready!"
fi

# Go development setup
echo ""
read -p "🐹 Set up Go development environment? (y/n): " setup_go
if [[ $setup_go =~ ^[Yy]$ ]]; then
    echo "Installing Go development tools..."
    
    if ! command -v go >/dev/null 2>&1; then
        pkg install -y golang
    fi
    
    # Set up Go environment
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    
    mkdir -p ~/go/{bin,src,pkg}
    
    echo "✅ Go development environment ready!"
fi

# Code editors setup
echo ""
echo "📝 Setting up code editors..."

# Vim configuration
if command -v vim >/dev/null 2>&1; then
    cat > ~/.vimrc << 'EOF'
" Basic Vim Configuration for Termux
set number
set syntax=on
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
set ignorecase
set smartcase
set ruler
set wildmenu
set cursorline
colorscheme desert

" Enable mouse support
set mouse=a

" File encoding
set encoding=utf-8

" Show matching brackets
set showmatch

" Enable folding
set foldmethod=indent
set foldlevel=99
EOF
    echo "✅ Vim configured!"
fi

# Create useful aliases
echo ""
echo "⚡ Setting up useful aliases..."
cat >> ~/.bashrc << 'EOF'

# Development aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias tree='tree -C'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git branch'
alias gco='git checkout'

# Python aliases
alias py='python'
alias pip='pip --user'

# Quick navigation
alias home='cd ~'
alias storage='cd /storage/emulated/0'
alias downloads='cd /storage/emulated/0/Download'

# System aliases
alias cls='clear'
alias h='history'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Development shortcuts
alias serve='python -m http.server 8000'
alias myip='curl ifconfig.me'
EOF

# SSH setup
echo ""
read -p "🔐 Set up SSH server? (y/n): " setup_ssh
if [[ $setup_ssh =~ ^[Yy]$ ]]; then
    echo "Setting up SSH server..."
    
    # Generate SSH key if it doesn't exist
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
        echo "✅ SSH key generated!"
    fi
    
    # Set up SSH server
    sshd
    echo "✅ SSH server started!"
    echo "📱 Connect using: ssh $(whoami)@$(hostname -I | cut -d' ' -f1) -p 8022"
fi

# Create development directories
echo ""
echo "📁 Creating development directories..."
mkdir -p ~/projects/{personal,work,experiments}
mkdir -p ~/scripts
mkdir -p ~/bin

echo ""
echo "🎉 DEVELOPMENT SETUP COMPLETE!"
echo "=============================="
echo ""
echo "📝 What's been set up:"
echo "   ✅ Git configuration"
if [[ $setup_python =~ ^[Yy]$ ]]; then
    echo "   ✅ Python development environment"
fi
if [[ $setup_node =~ ^[Yy]$ ]]; then
    echo "   ✅ Node.js development environment"
fi
if [[ $setup_go =~ ^[Yy]$ ]]; then
    echo "   ✅ Go development environment"
fi
echo "   ✅ Vim configuration"
echo "   ✅ Useful aliases"
if [[ $setup_ssh =~ ^[Yy]$ ]]; then
    echo "   ✅ SSH server"
fi
echo "   ✅ Development directories"
echo ""
echo "🚀 Next steps:"
echo "   - Restart your terminal or run: source ~/.bashrc"
echo "   - Check out your new aliases with 'alias'"
echo "   - Start coding in ~/projects/"
echo ""
echo "Happy coding! 🎯"