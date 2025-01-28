# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [UNRELEASED]

### Fixed

- Incorrect use of `fzf.default_opts` configuration option.
- Statusline not being redrawn sometimes after closing the fzf popup window.

### Added

- `cmd_actions` configuration option, allowing custom fzf key bindings in the
  ex-command picker window (default actions are documented in the helpfile).

### Changed

- `width` and `height` window options to `width_frac` and `height_frac`
  respectively (to homogenise API names with [`haunt.nvim`](https://git.sr.ht/~adigitoleo/haunt.nvim)).
- All `fzf` configuration options (backwards-incompatible; check helpfile
  documentation)

### Removed

- Old and incorrectly implemented test suite.
- Incorrectly implemented `winblend` window options.
- `highlight` and `preview` window options.

## [1.0.0] — 2024-06-04

## [0.2.1] — 2024-05-21

## [0.2.0] — 2024-05-21

## [0.1.1] — 2024-05-13

## [0.1.0] — 2024-05-04

[1.0.0]: https://git.sr.ht/~adigitoleo/quark.nvim/refs/v1.0.0
[0.2.1]: https://git.sr.ht/~adigitoleo/quark.nvim/refs/v0.2.1
[0.2.0]: https://git.sr.ht/~adigitoleo/quark.nvim/refs/v0.2.0
[0.1.1]: https://git.sr.ht/~adigitoleo/quark.nvim/refs/v0.1.1
[0.1.0]: https://git.sr.ht/~adigitoleo/quark.nvim/refs/v0.1.0
