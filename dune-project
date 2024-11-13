(lang dune 3.6)

(name korotohvost)

(generate_opam_files true)

(authors "Mikhail Lopatin <dx3mod@bk.ru>")

(maintainers "Mikhail Lopatin <dx3mod@bk.ru>")

(license MIT)

(package
 (name korotohvost)
 (synopsis "Tiny URL shortener")
 (depends
  ocaml
  dune
  dream
  caqti-lwt-unix
  mustache
  caqti-driver-sqlite3
  lwt_ppx))
