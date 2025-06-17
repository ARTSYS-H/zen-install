# zen-install

Install latest [Zen](https://zen-browser.app) version Easily, for non Flatpak users.

## Getting Started

To install Zen, you just need to download and run zen-install.sh 

```bash
wget https://raw.githubusercontent.com/ARTSYS-H/zen-install/refs/heads/main/zen-install.sh
chmod +x zen-install.sh

# yay, now you can use the script!
# NOTE: you need the following if not in your distro:
# wget, curl, bash (probably, untested on sh), uuidgen, tar
./zen-install.sh install
```
## Commands:

- **install [location]**
  Installs Zen to the specified location, or the default one (~/.zen/browser)

- **uninstall [location]**
  Removes Zen from the specified location, or the default one (~/.zen/browser)

  Note: this will keep your data should you wish to return or move it

- **uninstall-data**
  Fully removes Zen data from your system.

- **desktop [location]**
  Attempts to create a desktop entry for the specified installation of Zen, or the default one (~/.zen/browser)

## Tests

List of tested platforms:

| Platforms | Versions |        Test        |
|-----------|:--------:|:------------------:|
| Ubuntu    | `24.04`  | :white_check_mark: |

## Contribution

Contributions are welcome! If you have suggestions, bug fixes, or improvements, feel free to open an issue or a pull request.
