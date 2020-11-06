# homebrew-autoremove

*This command is now included in `brew`*

External Homebrew command for removing installed formuale that are no longer needed.

Like `apt autoremove` but for Homebrew.

## Installation

```sh
brew tap dawidd6/autoremove
```

## Usage

```sh
brew autoremove [-f | --force] [-n | --dry-run] [-h | --help]
```

When `--force` option is passed, script will **not** ask for confirmation!

