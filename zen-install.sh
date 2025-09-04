#!/bin/sh

# Fonction pour vérifier les dépendances
check_dependency() {
  # Liste des commandes requises
  commands="wget curl jq tar"
  commands_miss=""

  for cmd in $commands; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      if [ -z "$commands_miss" ]; then
        commands_miss="$cmd"
      else
        commands_miss="$commands_miss $cmd"
      fi
    fi
  done

  if [ -n "$commands_miss" ]; then
    echo "ERROR: The following commands are not installed:" 1>&2
    for cmd in $commands_miss; do
      echo "- $cmd" 1>&2
    done
    return 1
  else
    return 0
  fi
}

# Vérification des dépendances
if ! check_dependency; then
  exit 1
fi

# Emplacement d'installation par défaut
default_install_location="$HOME/.zen/browser"
zen_install="${2-$default_install_location}"

zen_download_file="zen.linux-x86_64.tar.xz"

# Récupération de la dernière version
zen_release_tag="$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r ".tag_name")"
if [ "$zen_release_tag" == "null" ]; then
  echo "ERROR: Can't get the latest version of Zen Browser." 1>&2
  exit 1
fi

zen_download_tarball="https://github.com/zen-browser/desktop/releases/download/$zen_release_tag/$zen_download_file"

zen_download_desktop_file="https://raw.githubusercontent.com/ARTSYS-H/zen-install/refs/heads/main/zen.desktop"

# Fonction de désinstallation
uninstall() {

  if [ -f "$zen_install/zen" ]; then
    echo "===== Zen install exists. Removing it! ====="
    rm -rfv $zen_install
  else
    echo "ERROR: Zen does not exist at $zen_install" 1>&2
    exit 1
  fi

  if [ -f "$HOME/.local/share/applications/zen.desktop" ]; then
    echo "===== Zen desktop file exists. Removing it! ====="
    rm -rfv "$HOME/.local/share/applications/zen.desktop"
    # refresh desktop environment
    if command -v update-update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$HOME/.local/share/applications/"
    fi
  fi

}

# Fonction pour supprimer les données
remove_data() {
  echo "===== Removing all Zen Data ! ====="
  rm -rfv "$HOME/.zen"
  rm -rfv "$HOME/.cache/zen"
}

# Fonction pour créer une entrée de bureau
desktop() {

  if [ ! -f "$zen_install/zen" ]; then
    echo "ERROR: Zen does not exist at $zen_install" 1>&2
    exit 1
  fi

  if [ ! -d "$HOME/.local/share/applications" ]; then
    echo "ERROR: $HOME/.local/share/applications doesn't exist. You may have to proceed manually!" 1>&2
    exit 1
  fi

  # temp_dir="/tmp/$(uuidgen)"
  # mkdir -p "$temp_dir"
  temp_dir=$(mktemp -d)

  echo "===== Downloading zen.desktop to $temp_dir/zen.desktop ====="
  wget -O "$temp_dir/zen.desktop" "$zen_download_desktop_file"

  # sanity check
  if [ ! -f "$temp_dir/zen.desktop" ]; then
      echo "ERROR: Something went wrong when downloading zen.desktop. It isn't present in $temp_dir/zen.desktop" 1>&2
      exit 1
  fi

  # Remplacement du chemin
  sed -i "s|\$zen_install|$zen_install|g" "$temp_dir/zen.desktop"

  mv "$temp_dir/zen.desktop" "$HOME/.local/share/applications/"
  rm -rf "$temp_dir"

  chmod +x "$HOME/.local/share/applications/zen.desktop"

  # refresh desktop environment
  if command -v update-update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications/"
  fi
    

  echo "===== Successfully added Zen Browser to your desktop entries! ====="
}

# Fonction d'installation
install() {

  echo "===== Using release tagged $zen_release_tag ====="

  if [ -f "$zen_install/zen" ]; then
    echo "ERROR: A Zen install already exists at $zen_install. Please remove it before installing Zen." 1>&2
    exit 1
  fi

  # temp_dir="/tmp/$(uuidgen)"
  # mkdir -p "$temp_dir/content"
  temp_dir=$(mktemp -d)

  echo "===== Downloading zen to $temp_dir/zen.tar.xz ====="
  wget -O "$temp_dir/zen.tar.xz" "$zen_download_tarball"

  echo "===== Extracting zen to $temp_dir/content ====="
  mkdir -p "$temp_dir/content"
  tar -xvJf "$temp_dir/zen.tar.xz" -C "$temp_dir/content"

  # sanity check
  if [ ! -f "$temp_dir/content/zen/zen" ]; then
      echo "ERROR: Something went wrong when downloading Zen. It isn't present in $temp_dir/content/zen" 1>&2
      exit 1
  fi

  mkdir -p "$zen_install"

  echo "===== Moving zen install to $zen_install ====="
  mv $temp_dir/content/zen/** "$zen_install/"

  echo "===== Removing temporary directory ====="
  rm -rf "$temp_dir"

  echo "=========================================="
  echo "======= Zen Browser is installed ! ======="
  echo "To make a desktop entry (so zen will appear on your system's navigation) use $0 desktop [location]"
  echo "To use open zen in terminals, use:"
  echo "PATH=\$PATH:$zen_install/zen"
  echo "=========================================="
  
}

help() {
    echo "help:"
    echo "  install [location]   -- installs the latest version of Zen to the specified directory"
    echo "  uninstall [location] -- removes Zen installation (but not data) from your system"
    echo "  remove-data -- removes Zen data from your system (Take care!)"
    echo "  desktop [location] -- creates a desktop entry for your Zen installation"
    echo "  help -- you should know what this does since you're here :)"
    echo ""
    echo "note: location defaults to $HOME/.zen/browser (recommanded) if unspecified"
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    help
    exit 1
fi

# Get the command and the argument
command=$1

case $command in
    install)
        install $2
        ;;
    uninstall)
        uninstall $2
        ;;
    remove-data)
        remove_data
        ;;
    desktop)
        desktop $2
        ;;
    help)
        help
        ;;
    *)
        echo "Error: Unknown command '$command'." 1>&2
        help
        ;;
esac
