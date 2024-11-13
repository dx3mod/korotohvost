# korotohvost

A tiny URL shortener for your localhost. <3

> [!WARNING]
> In active development now!

## Manual Usage

### Installation 

**Requirements**

- [OCaml] >= 4.14
- [Sqlite3]

Install latest development version by [OPAM] package manager.
```console
$ opam pin https://github.com/dx3mod/korotohvost.git 
```

### Prepare database

Setup tables.
```console
$ sqlite3 your-db.sqlite3 < migrations/base.sql
```

[OCaml]: https://ocaml.org/
[OPAM]: https://opam.ocaml.org/
[Sqlite3]: https://www.sqlite.org/

### Run 

```console
$ dune exec korotohvost 
```