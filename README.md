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
    * A [.gitconfig](/.gitconfig) file has been pre-configured to support
      properly managing line endings inside the repository using the correct
      `core.autocrlf` setting (`false`).
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

1. Update the following files:
    * `README.md`
        * Update the title.
        * Update the description.
        * Remove everything else except license.
    * `LICENSE.md`
        * Change license to your project license.
    * `CONTRIBUTING.md`
        * Update code style guidelines (if applicable).
    * `CODE_OF_CONDUCT.md`
        * Update project administrators (if applicable).
    * `SECURITY.md`
        * Update where to report security vulnerabilities.
        * Update support versions table.
    * `.cspell/dictionaries/project.txt`
        * Remove all words and add those you do need.
    * `.github/FUNDING.yml`
        * Add your funding information (if applicable).
    * `.github/CODEOWNERS`
        * Set your code owners (if applicable).
1. Link `.gitconfig` into repository config by adding the following snippet into
   your local `.git/config` at the top:
```ini
[include]
    path="../.gitconfig"
```
* [ ] Done
2. Run `./scripts/setup-pre-commit.sh` to install and configure `pre-commit`.
* [ ] Done
3. Set up GitHub labels from the `.github/labels.yaml` file (if applicable).
* [ ] Done
4. Set up GitHub rulesets from the files inside `.github/samples/rulesets`
   (if applicable).
* [ ] Done
5. Update GitHub Dependabot setup (if applicable).
* [ ] Done
6. Enable VSCode integrations.
* [ ] Done
7. Good to go!
* [ ] Yay!

## License ##

Copyright (c) 2025 to present G'lek Tarssza

Licensed under a customized MIT license.

See [LICENSE.md](LICENSE.md) for the full license.
