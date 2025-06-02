# Repository Template #

A starter template for my repositories.

<!-- omit in toc -->
## Table of Contents ##

* [Repository Template](#repository-template)
    * [About](#about)
    * [Setup](#setup)
    * [License](#license)

## About ##

This template repository is set up to support the following:

* [Git (obviously)](https://git-scm.com/)
    * A [.gitattributes](/.gitattributes) file has been pre-configured to treat
      all files as text with Unix-style (LF) line endings **except** for `.cmd`
      and `.bat` files. These files are treated as text files with Windows-style
      (CRLF) line endings.
    * A [.gitignore](/.gitignore) file has been pre-configured to ignore most
      Visual Studio Code files **except** `extensions.json`, `tasks.json`,
      `launch.json`, and any `.code-snippets` files. It also ignores any
      Vim-related files, log files (`*.log*`), and local environment files
      (`.env*`).
* [`pre-commit`](https://pre-commit.com/)
    * [.pre-commit-config.yaml](/.pre-commit-config.yaml) file is provided with some relatively sane
      default hooks. Feel free to adjust to your liking.
* [EditorConfig](https://editorconfig.org/)
    * A pre-configured `.editorconfig` file is provided which treats all files
      as UTF-8 encoded files with Unix-style (LF) line endings **except** for
      `.cmd` and `.bat` files. Those are have Windows-style (CRLF) line endings.
    * Additionally all files are indented with spaces, 4 per indentation level,
      **except** `.yaml` or `.yml` files. Those are indented with 2 spaces per
      indentation level.
    * The file is pre-configured to insert a final newline as per
      [the POSIX standard](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_206).
    * Finally, the file is configured to trim trailing whitespace.
* [Visual Studio Code](https://code.visualstudio.com/)
* [GitHub](https://github.com/)
    * [Integration with Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=GitHub.remotehub)
* [GitHub Pull Requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
    * [Integration with Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github)
* [GitHub Actions](https://github.com/features/actions)
    * [Integration with Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-github-actions)
* [CSpell Spell Checker](https://cspell.org/)
    * A [cspell.json](/cspell.json) is pre-configured to be read-only and use a
      set of project-specific dictionary provided at
      [.cspell/dictionaries/project.txt](/.cspell/dictionaries/).
    * The above mentioned dictionary configurations are located at
      [.cspell/configs/](/.cspell/configs/).

## Setup ##

1. Install `python`.

See your operating system documentation for relevant instructions.

2. Install `pipx`.

```sh
# === Ubuntu >=23.04/Debian ===
sudo apt update
sudo apt install pipx
pipx ensurepath
# Optionally, to allow --global
sudo pipx ensurepath --global

# === Fedora ===
sudo dnf install pipx
pipx ensurepath
# Optionally, to allow --global
sudo pipx ensurepath --global

# === Arch Linux ===
sudo pacman -S python-pipx
pipx ensurepath
# Optionally, to allow --global
sudo pipx ensurepath --global

# === macOS ===
brew install pipx
pipx ensurepath
# Optionally, to allow --global
sudo pipx ensurepath --global

# === Windows via Scoop ===
scoop install pipx
pipx ensurepath

# === Via pip everywhere else ===
python3 -m pip install --user pipx
python3 -m pipx ensurepath
# Optionally, to allow --global if applicable
sudo pipx ensurepath --global
```

See [the `pipx` website](https://pipx.pypa.io/stable/) for more details.

3. Install `pre-commit`.

```sh
pipx install pre-commit
pre-commit install
```

See [the `pre-commit` website](https://pre-commit.com/#install) for more
details.

4. Good to go!

## License ##

Copyright (c) 2025 G'lek Tarssza

All rights reserved.

See [LICENSE.md](LICENSE.md) for the full license.
