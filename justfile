mod build "just/build.just"
mod clean "just/clean.just"
mod test "just/test.just"

_default:
  @just --list --justfile {{ justfile() }}
