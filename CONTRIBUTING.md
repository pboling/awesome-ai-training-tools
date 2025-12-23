# Contributing to Awesome AI Training Tools

Thanks for your interest in contributing! This repository is a curated "awesome" list of tools used to design, manage, and evaluate AI training tasks. The list content is released under CC0 and the scripts in `scripts/` are licensed under MIT (see `README.md`).

This document explains how to propose changes, add examples or scripts, and prepare a clean pull request so maintainers can review and accept your contribution quickly.

## Table of contents

- How to propose a change
- Formatting and content guidelines
- Adding scripts/examples
- Pull request checklist
- Licensing and attribution
- Review process and maintainers

## How to propose a change

1. Open an issue first for non-trivial changes (new categories, large reorganization, or debates about inclusion criteria). For small fixes (typos, small description edits, adding a tool), opening a PR is fine.
2. Fork the repository and create a branch with a descriptive name, e.g. `add/harbor-setup-script` or `fix/label-studio-link`.
3. Make your changes on the branch and include a clear description in the PR body explaining what you changed and why. If you add an entry, include:
   - Project name and a single-line description.
   - A working upstream URL.
   - Any notes about usage or why it belongs in this list.
4. Submit the pull request against the `main` branch of this repository.

## Formatting and content guidelines

- Use Markdown and follow the repository's existing style and structure.
- Keep each list item concise: project name (linked) followed by a short dash and a short description. Example:

  - **[Harbor](https://github.com/laude-institute/harbor)** - Next-generation platform for designing and managing structured AI training tasks with human-in-the-loop workflows.

- Avoid editorializing or promotional language. Prefer objective descriptions and links to the official project page or repo.
- Keep categories focused. Place tools in the most appropriate existing category; propose a new category only when multiple related entries justify it.

## Adding scripts and examples

This repository also hosts setup scripts and small helper scripts under `scripts/`.

If you add a script:

- Place it under an appropriate subdirectory inside `scripts/`, e.g. `scripts/harbor/`.
- Ensure the script has an appropriate shebang (`#!/usr/bin/env bash`) and is executable where applicable.
- Add a short note in `README.md` linking to the script (maintainers may do this when reviewing your PR if you forget).
- License your script under MIT (the repository's scripts are MIT-licensed). If your script has a different license, include a clear license header and explain compatibility in the PR.
- Add a one-line description in the README or a short usage section in the script file itself explaining what the script does and any prerequisites.

## Pull request checklist

Before marking your PR ready for review, please ensure:

- [ ] The change is limited to one purpose (e.g., add a single tool, fix typos, or add a script).
- [ ] Links are valid and resolve to the intended page.
- [ ] Descriptions are concise and neutral.
- [ ] For scripts: runtime requirements, usage notes, and license are documented.
- [ ] Your branch name and PR title are descriptive.

## Licensing and attribution

- The awesome list content (the README and list entries) should be compatible with CC0. By contributing list entries you agree to share them under the repository's glossary license unless explicitly stated otherwise.
- Scripts contained under `scripts/` follow the repository's MIT license. When contributing a script, ensure you have the right to license it under MIT and include a license header if possible.

If you are adding a third-party project to the list, do not add copied code from that project into this repository—link to it instead and ensure the project's license allows redistribution where relevant.

## Review process and maintainers

- Maintainers will review PRs and may request edits (formatting, description, or placement). Please respond to review comments so the PR can be merged.
- For editorial or large changes, maintainers may ask to open an issue first to discuss scope.

If you're unsure where to start or need guidance on whether a project belongs in this list, open an issue and tag a maintainer.

---

Thanks for helping keep this list useful and accurate! If you'd like a CODE_OF_CONDUCT or templates (PR/issue), feel free to open an issue requesting them and the maintainers will prioritize adding them.

