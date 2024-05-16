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

Once Hammer Kerl is installed, you can just run:

`erl`, and you'll be prompted. If, however, you've already how an Erlang
installation activated with `kerl`, then Erlang will just run.

## Verion History

### 0.1.0

* Initial version.
* Can list Erlang versions built, and allow updating shell config with
  preferred version

## Author

Copyright 2024 Jesse Gumm - MIT Licensed
