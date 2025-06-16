#!/usr/bin/env bash

default_install_location="$HOME/.zen/browser"
zen_install="${default_install_location}"

if ! type "zenity" &>/dev/null; then
  echo "Error: zenity is required for this install script." 1>&2
  exit 1
fi

zen_download_file="zen.linux-x86_64.tar.xz"

zen_release_tag="$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | jq -r ".tag_name")"
if [[ "$zen_release_tag" == "null" ]]; then
  zenity --error --no-wrap --text="Can't get the latest version of Zen Browser."
  exit 1
fi

zen_download_tarball="https://github.com/zen-browser/desktop/releases/download/$zen_release_tag/$zen_download_file"

function download_zen {

  echo "#Create temporary directory"
  temp_dir="/tmp/$(uuidgen)"
  mkdir -p "$temp_dir/content"

  echo "#Downloading zen to $temp_dir/zen.tar.xz"
  wget -O "$temp_dir/zen.tar.xz" "$zen_download_tarball"

  echo "#Extracting zen to $temp_dir/content"
  tar -xvJf "$temp_dir/zen.tar.xz" -C "$temp_dir/content"

  echo "#Sanity Check"
  if [ ! -d "$temp_dir/content/zen" ]; then
    zenity --error --no-wrap --text="Something went wrong when downloading Zen.\nIt isn't present in $temp_dir/content/zen"
    exit 1
  fi

  echo "#Moving Zen install to $zen_install"
  mkdir -p "$zen_install"
  mv $temp_dir/content/zen/** "$zen_install/"

  echo "#Removing temporary directory"
  rm -rf "$temp_dir"
  
}

function uninstall {

  if ! zenity --title="Uninstall Zen Browser" --question --text="Do you want to proceed ?"; then
    exit 0
  fi

  if [ -d "$zen_install" ]; then
    rm -rf $zen_install
  else
    if ! zen_install="$(zenity --title="Select install location of Zen Browser" --file-selection --directory)/browser"; then
      exit 1
    fi
    rm -rf $zen_install
  fi

  if zenity --title="Uninstall Zen Browser" --question --text="Do you want to remove data ?"; then
    rm -rf "$HOME/.zen"
    rm -rf "$HOME/.cache/zen"
  fi

}

function desktop {

  if [! -d "$zen_install"]; then
    zenity --error --no-wrap --text="Zen does not exist a $zen_install"
    exit 1
  fi

  if [! -d "$HOME/.local/share/applications"]; then
    zenity --error --no-wrap --text="$HOME/.local/share/applications doesn't exist.\nYou may have to proceed manually!"
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

  update-desktop-database "$HOME/.local/share/applications/"

  zenity --info --no-wrap --text="Successfully added Zen Browser to your desktop entries!"
}

function install {

  user_location=$(zenity --title="Zen Browser $zen_release_tag" --list --text="Select the Install Path" --column="Path" --column="" "$default_install_location" "Recommanded default install location" "Select" "Select the install location")

  case "$user_location" in
    Select)
      if ! zen_install="$(zenity --title="Select install location of Zen Browser" --file-selection --directory)/browser"; then
        exit 1
      fi
      ;;
    "")
      exit 0
      ;;
    *)
      zen_install="$user_location"
      ;;
  esac
  
  if [ -d "$zen_install" ]; then
    zenity --error --no-wrap --text="A Zen install already exists at $zen_install.\nPlease remove it before installing Zen."
    exit 1
  fi

  (download_zen) | zenity --title="Install Zen Browser $zen_release_tag" --progress --pulsate --no-cancel --auto-close

  if zenity --title="Zen Browser is installed!" --question --text="To use open zen in terminals, use: PATH=\$PATH:$zen_install/zen\nDo you want a desktop entry ? (so zen will appear on your system's navigation)"; then
    desktop
  else
    exit 0
  fi

}

action=$(zenity --title="Zen Browser $zen_release_tag" --list --hide-header --text="Select the Action" --column="Action" Install Uninstall)

case "$action" in
  Install)
    install
    ;;
  Uninstall)
    uninstall
    ;;
  "")
    exit 0
    ;;
  *)
    zenity --error --no-wrap --text="Unsuported action."
    exit 1
    ;;
esac
