<img src="https://raw.githubusercontent.com/gabyx/githooks/main/docs/githooks-logo.svg" style="margin-left: 20pt" align="right">

# Githooks for Shell Scripts

This repository contains shared repository Git hooks for shell scripts in
`githooks/*` to be used with the
[Githooks Manager](https://github.com/gabyx/Githooks).

The following hooks are included:

- Hook to format shell files with `shfmt` (pre-commit).
- Hook to check shell files with `shellcheck` (pre-commit).
- Hook to check shell mistakes (pre-commit).

<details>
<summary><b>Table of Content (click to expand)</b></summary>

<!-- TOC -->

- [Githooks for Shell Scripts](#githooks-for-shell-scripts)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Hooks](#hooks)
    - [Format Shell: `pre-commit/1-format/format-shell.yaml`](#format-shell-pre-commit1-formatformat-shellyaml)
    - [Check Shell Mistakes: `pre-commit/2-check/check-shell-mistakes.yaml`](#check-shell-mistakes-pre-commit2-checkcheck-shell-mistakesyaml)
    - [Check Shell: `pre-commit/2-check/check-shell.yaml`](#check-shell-pre-commit2-checkcheck-shellyaml)
  - [Scripts](#scripts)
  - [Testing](#testing)

</details>

## Requirements

Run them
[containerized](https://github.com/gabyx/Githooks#running-hooks-in-containers)
where only `docker` is required.

If you want to run them non-containerized, make the following installed on your
system:

- `bash`
- [`shfmt`](https://github.com/mvdan/sh#shfmt)
- [`shellcheck`](https://github.com/koalaman/shellcheck#installing)
- GNU `grep`
- GNU `sed`
- GNU `find`
- GNU `xargs`
- GNU `parallel` _[optional]_

This works with Windows setups too.

## Installation

The hooks can be used by simply using this repository as a shared hook
repository inside your repository.
[See further documentation](https://github.com/gabyx/githooks#shared-hook-repositories).

You should configure the shared hook repository in your project to use this
repos `main` branch by using the following `.githooks/.shared.yaml` :

```yaml
version: 1
urls:
  - https://github.com/gabyx/githooks-shell.git@main`.
```

## Hooks

### Format Shell: `pre-commit/1-format/format-shell.yaml`

Formatting with `shfmt`.

### Check Shell Mistakes: `pre-commit/2-check/check-shell-mistakes.yaml`

Mistakes such as wrong `shellcheck` ignore format and 'set -x' are checked.

### Check Shell: `pre-commit/2-check/check-shell.yaml`

Linting file with `shellcheck`.

## Scripts

The following scripts are provided:

- [`format-shell-all.sh`](githooks/scripts/format-shell-all.sh) : Script to
  format all shell files in a directory recursively. See documentation.

- [`check-shell-all.sh`](githooks/scripts/check-shell-all.sh) : Script to check
  all shell files in a directory recursively. See documentation.

They can be used in scripts by doing the following trick inside a repo which
uses this hook:

```shell
shellHooks=$(git hooks shared root ns:githooks-shell)
"$shellHooks/githooks/scripts/<script-name>.sh"
```

## Testing

The containerized tests in `tests/*` are executed by

```bash
tests/test.sh
```

or only special tests steps by

```bash
tests/test.sh --seq 001..010
```

For showing the output also in case of success use:

```bash
tests/test.sh --show-output [other-args]
```
