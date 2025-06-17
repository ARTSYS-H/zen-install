#!/usr/bin/env bash

function check_dependency {
    commands=("wget" "curl" "jq" "uuidgen" "tar")
    commandes_miss=()

    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            commandes_miss+=("$cmd")
        fi
    done

    if [ ${#commandes_miss[@]} -ne 0 ]; then
        echo "Error: The following commands are not installed:" 1>&2
        for cmd in "${commandes_miss[@]}"; do
            echo "- $cmd" 1>&2
        done
        return 1
    else
        return 0
    fi
}

if ! check_dependency; then
  exit 1
fi

default_install_location="$HOME/.zen/browser"
zen_install="${2-$default_install_location}"

zen_download_file="zen.linux-x86_64.tar.xz"

zen_release_tag="$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r ".tag_name")"
if [[ "$zen_release_tag" == "null" ]]; then
  echo "Error: Can't get the latest version of Zen Browser." 1>&2
  exit 1
fi

zen_download_tarball="https://github.com/zen-browser/desktop/releases/download/$zen_release_tag/$zen_download_file"

function uninstall {

  if [ -f "$zen_install/zen" ]; then
    echo "===== Zen install exists. Removing it! ====="
    rm -rfv $zen_install
  else
    echo "Error: Zen does not exist at $zen_install" 1>&2
    exit 1
  fi

  if [ -f "$HOME/.local/share/applications/zen.desktop" ]; then
    echo "===== Zen desktop file exists. Removing it! ====="
    rm -rfv "$HOME/.local/share/applications/zen.desktop"
    # refresh desktop environment
    update-desktop-database "$HOME/.local/share/applications/"
  fi

}

function uninstall_data {
  echo "===== Removing all Zen Data ! ====="
  rm -rfv "$HOME/.zen"
  rm -rfv "$HOME/.cache/zen"
}

function desktop {

  if [ ! -f "$zen_install/zen" ]; then
    echo "Error: Zen does not exist at $zen_install" 1>&2
    exit 1
  fi

  if [ ! -d "$HOME/.local/share/applications" ]; then
    echo "Error: $HOME/.local/share/applications doesn't exist. You may have to proceed manually!" 1>&2
    exit 1
  fi

  temp_dir="/tmp/$(uuidgen)"
  mkdir -p "$temp_dir"

  cat << EOF > "$temp_dir/zen.desktop"
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Name=Zen Browser
Comment=Experience tranquillity while browsing the web without people tracking you!
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=$zen_install/zen %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=$zen_install/browser/chrome/icons/default/default128.png
Categories=GNOME;GTK;Network;WebBrowser;Internet;Utility;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
EOF

  mv "$temp_dir/zen.desktop" "$HOME/.local/share/applications/"
  rm -rf "$temp_dir"

  chmod +x "$HOME/.local/share/applications/zen.desktop"

  # refresh desktop environment
  update-desktop-database "$HOME/.local/share/applications/"

  echo "===== Successfully added Zen Browser to your desktop entries! ====="
}

function install {

  echo "===== Using release tagged $zen_release_tag ====="

  if [ -f "$zen_install/zen" ]; then
    echo "Error: A Zen install already exists at $zen_install. Please remove it before installing Zen." 1>&2
    exit 1
  fi

  temp_dir="/tmp/$(uuidgen)"
  mkdir -p "$temp_dir/content"

  echo "===== Downloading zen to $temp_dir/zen.tar.xz ====="
  wget -O "$temp_dir/zen.tar.xz" "$zen_download_tarball"

  echo "===== Extracting zen to $temp_dir/content ====="
  tar -xvJf "$temp_dir/zen.tar.xz" -C "$temp_dir/content"

  # sanity check
  if [ ! -f "$temp_dir/content/zen/zen" ]; then
      echo "Error: Something went wrong when downloading Zen. It isn't present in $temp_dir/content/zen" 1>&2
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

function help {
    echo "help:"
    echo "  install [location]   -- installs the latest version of Zen to the specified directory"
    echo "  uninstall [location] -- removes Zen installation (but not data) from your system"
    echo "  uninstall-data -- removes Zen data from your system (Take care!)"
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
    uninstall-data)
        uninstall_data
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
