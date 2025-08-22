# manual installs prior to running script

# ----FUNCTIONS-----

check_and_install_app() {
 local app_name=$1
 local brew_cask_name=$2

 if [ -d "/Applications/$app_name.app" ]; then
  echo "$app_name is already installed."
 else 
  echo "Installing $app_name"
  brew install --cask "$brew_cask_name"
  echo "Opening $app_name"
  open -a "$app_name.app"
 fi
}

check_and_install_cli() {
 local cli_name=$1

 if brew list $cli_name &>/dev/null; then
  echo "ℹ️' $cli_name' is already installed via Homebrew."
 else
  echo "📦 '$cli_name' is not installed. Installing via Homebrew..."
  brew install $cli_name

  # Check if the installation succeeded
  if brew list $cli_name &>/dev/null; then
   echo "✅ '$cli_name' successfully installed."
  else
   echo "❌ Failed to install '$cli_name'."
   exit 1
  fi
 fi
}

check_and_install_cask() {
 local cask_name=$1

 if brew list --cask $cask_name &>/dev/null; then
  echo "ℹ️  '$cask_name' is already installed via Homebrew Cask."
 else
  echo "📦 '$cask_name' is not installed. Installing via Homebrew Cask..."
  brew install --cask $cask_name

  # Check if installation succeeded
  if brew list --cask $cask_name &>/dev/null; then
   echo "✅ '$cask_name' successfully installed."
  else
   echo "❌ Failed to install '$cask_name'."
   exit 1
  fi
 fi
}

install_latest_stable_runtime() {
  local plugin_name="$1"
  local plugin_repo="$2"

  # Add plugin if not already present
  if asdf plugin list | grep -q "^${plugin_name}$"; then
    echo "🔹 Plugin ${plugin_name} already added."
  else
    echo "➕ Adding plugin ${plugin_name} from ${plugin_repo}..."
    asdf plugin add "$plugin_name" "$plugin_repo"
  fi

  # Find the latest stable version (only numeric versions, ignore betas/RCs)
  case "$plugin_name" in
    java)
      # Pick the latest openjdk (you could also choose temurin, oracle, etc.)
      latest_version=$(asdf list all java | grep '^openjdk-' | tail -1)
      ;;
    *)
      # For everything else, only numeric versions
      latest_version=$(asdf list all "$plugin_name" | grep -E '^[0-9]+(\.[0-9]+)*$' | tail -1)
      ;;
  esac

  if [ -z "$latest_version" ]; then
    echo "❌ Could not find a stable version for ${plugin_name}"
    exit 1
  fi

  echo "⬇️ Installing ${plugin_name} ${latest_version}..."
  asdf install "$plugin_name" "$latest_version"

  echo "✅ ${plugin_name} ${latest_version} installed and set."
}

# Optional apps to install manuall
#LibreOffice
#Notion

# --------Manual Actions-------------
# grant Mac calendar access to Google account's calendar

# --------Mac settings---------------
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Keyrepeat (these are faster than the defaults possible in the preferences panel)
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 1

# --------Create directories--------
cd && mkdir -p dev
cd ~/dev && mkdir -p downloads
cd ~/dev && mkdir -p projects
cd ~/dev/projects && mkdir -p internal
cd ~/dev/projects && mkdir -p external

# --------Install brew--------------
if command -v brew &> /dev/null; then
  echo "✅ Homebrew is already installed, so skipping"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Updateing Homebrew..."
brew update

# --------Install Applications------
check_and_install_app "Google Chrome" "google-chrome"
check_and_install_app "Discord" "discord"
check_and_install_app "Slack" "slack"
check_and_install_app "Visual Studio Code" "visual-studio-code"
check_and_install_app "Cursor" "cursor"

if [ ! -f ~/.zprofile ]; then
  echo >> ~/.zprofile
fi

cd
if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ".zprofile";then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --------Install Shells and CLIs---

# install oh my zsh
if [ ! -d ~/.oh-my-zsh ];
then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo ℹ️  'oh my zsh' is already installed
fi

# libyaml (required to install ruby via asdf, which is required for ios stuff)
check_and_install_cask "iterm2"
check_and_install_cask "warp"
check_and_install_cask "docker"
check_and_install_cli "libyaml"
check_and_install_cli "neovim"
check_and_install_cli "ollama"
check_and_install_cli "docker"

# --------Install asdf--------------
# https://github.com/asdf-vm/asdf
check_and_install_cli "asdf"

# add asdf shims directory to path
cd
if grep -q 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' ".zshrc";then
  echo "ℹ️  'asdf' shims directory already exists in path."
else
  echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.zshrc
  
  if grep -q 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' ".zshrc";then
    echo "✅ 'asdf' shims successfully added to path"
  else
    echo "❌ Failed to add 'asdf' shims directory to path."
  fi
fi

# --------Install Common Versions----
# node

install_latest_stable_runtime "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git"
install_latest_stable_runtime "python" "https://github.com/danhper/asdf-python.git"
install_latest_stable_runtime "ruby" "https://github.com/asdf-vm/asdf-ruby.git"
install_latest_stable_runtime "rust" "https://github.com/asdf-community/asdf-rust.git"
install_latest_stable_runtime "java"

# --------Install Claude Code--------
npm install -g @anthropic-ai/claude-code
claude --version

# aliases
zshrc_file="$HOME/.zshrc"

ALIASES=(
    "alias grc='git rebase --continue'"
    "alias gri='git rebase --interactive $1'"
    "alias gs='git status'"
    "alias gac='git add . && git commit -m $1'"
    "alias crap='git add . && git commit --amend --no-edit'"
    "alias derp='git add . && git commit --amend'"
    "alias dev='cd ~/dev'"
    "alias ll='ls -al'"
    "alias pro='cd ~/dev/projects/internal'"
)

ZSHRC_FILE="$HOME/.zshrc"

for alias_def in "${ALIASES[@]}"; do
    # Check if the alias already exists and update it, or add it if it doesn't
    if grep -q "$alias_def" "$ZSHRC_FILE"; then
        echo "ℹ️  $alias_def already exists in $zshrc_file"
    else
        echo "Adding alias: $alias_def"
        echo "$alias_def" >> "$ZSHRC_FILE"
        echo "✅ $alias_def added to $zshrc_file"
    fi
done

echo "Aliases updated in $ZSHRC_FILE. Sourcing the file..."
source "$ZSHRC_FILE"

echo "Aliases loaded."

# environment variables for libyaml (installed above), which is required for Ruby psych extension
cd
if ! grep -Fxq "export LDFLAGS" "$zshrc_file"; then
  echo "export LDFLAGS='-L/opt/homebrew/opt/libyaml/lib'"
  echo "✅ environment variable LDFLAGS added to $zshrc_file"
else
  echo "ℹ️  environment variable 'LDFLAGS' already exists in $zshrc_file"
fi
if ! grep -Fxq "export CPPFLAGS" "$zshrc_file"; then
  echo "export CPPFLAGS='-I/opt/homebrew/opt/libyaml/include'"
  echo "✅ environment variable CPPFLAGS added to $zshrc_file"
else
  echo "ℹ️  environment variable 'CPPFLAGS' already exists in $zshrc_file"
fi
if ! grep -Fxq "export PKG_CONFIG_PATH" "$zshrc_file"; then
  echo "export PKG_CONFIG_PATH='/opt/homebrew/opt/libyaml/lib/pkgconfig'"
  echo "✅ environment variable PKG_CONFIG_PATH added to $zshrc_file"
else
  echo "ℹ️  environment variable 'PKG_CONFIG_PATH' already exists in $zshrc_file"
fi

DULL_RED="\033[2;31m"
RESET="\033[0m"
echo "🔄 Reload $zshrc_file with the following command"
echo "    ${DULL_RED}source ~/.zshrc${RESET}"

