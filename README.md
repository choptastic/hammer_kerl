# Hammer Kerl

Hammer Kerl is a terminal-based menu-system around
[Kerl](https://github.com/kerl/kerl), the most excellent Erlang build and
installation management system.

And while Kerl is indeed very excellent, I sometimes forget certain details
about how kerl works (building, installing, and activating).

To alleviate some of my own confusions, I built Hammer Kerl as a tool to assist
with the managing Kerl's most basic features, and so that when I forget a
thing, the menu will help guide me.

## Install

```bash
git clone https://github.com/choptastic/hammer_kerl

cd hammer_kerl

sudo make install
```

## Usage

Once Hammer Kerl is installed, you can just run `hammer_kerl` from the terminal
to see what it can do.

Additionally, after `hammer_kerl` is installed, if you run `erl` or`escript`
and you'll be prompted with the Hammer Kerl menu if there is no
`kerl`-activated version of Erlang. If, however, you've already have a
`kerl`-activated Erlang installation, then Erlang will just run.

## Features

* Download, Build, and Install versions of Erlang (from a list of available
  versions)
* Delete installed or built versions of Erlang
* Activate installed versions
* Auto-add the kerl activation scripts to your shell startup scripts (so you
  don't have to activate every time or mess about with the shell startup
  scripts yourself).

## TODO

* Prompt to automatically install all dependencies.

## Verion History

### 0.2.1

* Fixed a typo in the install process
* Update the script so it runs on more environments (using `env` instead of
  `/usr/bin/perl`).

### 0.2.0

* Added **Install Erlang** option, which will download, build, and/or install
  Erlang as necessary from a menu of available releases.
* Added **Delete Erlang** option, which, like a sledgehammer, will delete
  Erlang installations and builds of the selected version.

### 0.1.0

* Initial version.
* Can list Erlang versions built, and allow updating shell config with
  preferred version

## Author

Copyright 2024 [Jesse Gumm](http://jessegumm.com) - [MIT Licensed](https://github.com/choptastic/hammer_kerl/blob/master/LICENSE.md)
