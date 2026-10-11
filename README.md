# vim-static

Portable builds of [Vim](https://www.vim.org/) and its `xxd` hex dumper, with ncurses linked in statically, built with [zig](https://ziglang.org) as the C toolchain.

- Linux glibc: only glibc is linked dynamically, and only symbols up to glibc 2.17, so the
  binaries run on anything from CentOS 7 onwards
- Linux musl (`--static`): fully static, no runtime dependencies at all (e.g. Alpine)
- macOS: only libSystem is dynamic (it ships with macOS, which has no fully static binaries)

Common terminal descriptions (xterm, xterm-256color, screen, screen-256color, tmux, tmux-256color,
linux, vt100, vt220, rxvt, alacritty, kitty, foot, wezterm, ...) are compiled into ncurses, so vim
works even on systems without a terminfo database. The system database is still used first, from
`/etc/terminfo`, `/lib/terminfo`, `/usr/share/terminfo`, and `/usr/lib/terminfo`, or from
`$TERMINFO`, `$TERMINFO_DIRS`, and `~/.terminfo`.

The build has the huge feature set without a GUI, X11, and scripting interpreters (Python, Perl,
Ruby, Lua, Tcl), and without translations. Vim finds its runtime files, which the archive has in
`share/vim`, through `$VIM`, e.g. `VIM=<prefix>/share/vim`, or at `/usr/local/share/vim`.

## Prerequisites

- `zig`, GNU make (the `make` 3.81 of macOS is enough), `git`

## Installation

Clone the repo with submodules (shallow, the history of the vendored projects is not needed):

```shell
git clone --recurse-submodules --shallow-submodules https://github.com/zshsetup/vim-static
cd vim-static
```

## Usage

```shell
./build.sh
```

Output is installed under `dist/`:

- `dist/bin/vim`, `dist/bin/xxd`: the binaries
- `dist/share/vim`: the runtime files (syntax, plugins, help, ...)
- `dist/share/man`: the man pages

Pass `--static` for the fully static musl build on Linux (output in `dist-static/`), `--clean` to
remove previous build output first, and `--jobs N` to control parallelism.

To run the smoke tests against the build:

```shell
./tests/run_smoke_tests.sh            # dist/
./tests/run_smoke_tests.sh --static   # dist-static/
```

## Releases

Publishing a GitHub release tagged like the contents of `VERSION`, the tag checked out in
`vendor/vim`, builds and attaches `vim-static-<platform>.tar.gz` for `macos-arm64`,
`linux-amd64`, `linux-arm64`, `linux-musl-amd64`, and `linux-musl-arm64`, together with the sources
they were built from (`vim-static-sources.tar.gz`).

To update a vendored project, check out a new release tag in its submodule, commit it, and update
`VERSION` if it is the main one, e.g.
`git -C vendor/vim fetch --depth 1 origin tag v9.2.1174 && git -C vendor/vim checkout v9.2.1174`.

## Acknowledgments

This repository builds and vendors the following upstream projects, unmodified, as git
submodules under `vendor/`. Credit goes to their respective authors:

- [Vim](https://github.com/vim/vim) by Bram Moolenaar and the Vim contributors
- [xxd](https://github.com/vim/vim/tree/master/src/xxd) by Juergen Weigert and contributors
- [ncurses](https://invisible-island.net/ncurses/) by Thomas E. Dickey and Free Software Foundation, Inc.

## License

MIT for the code in this repository. See `NOTICE` for the licenses of the upstream projects and the
resulting binaries, which are the Vim license (vim) and X11-MIT or GPL-2.0 at your choice (xxd).
