mod build "just/build.just"
mod clean "just/clean.just"
mod test "just/test.just"
mod manual "just/manual.just"

_default:
  @just --list --justfile {{ justfile() }}
