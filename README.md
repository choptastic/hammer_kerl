# Hammer Kerl

[Kerl](https://github.com/kerl/kerl) is an excellent tool for installing
Erlang, but managing the existing installations can sometimes be a pain.

Hammer Kerl is a tool to assist `kerl`.

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

## Verion History

### 0.2.0

* Added functions to install and delete Erlang functions.

### 0.1.0

* Initial version.
* Can list Erlang versions built, and allow updating shell config with
  preferred version

## Author

Copyright 2024 [Jesse Gumm](http://jessegumm.com) - [MIT Licensed](https://github.com/choptastic/hammer_kerl/blob/master/LICENSE.md)
