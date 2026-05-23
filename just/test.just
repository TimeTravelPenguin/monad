[no-cd]
all:
    #!/usr/bin/env sh

    files="$(find ./tests -type f -iname 'test.typ' -print | sort)"

    if [ -z "$files" ]; then
      echo "No tests found."
      exit 0
    fi

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    passed=0
    failed=0
    fail_names=""

    printf '%s\n' "$files" | while IFS= read -r file; do
      name="$(basename "$(dirname "$file")")"
      out="$tmp/$name.pdf"

      if typst c --root . "$file" "$out" 2>"$tmp/$name.err"; then
        printf "  ok   %s\n" "$name"
        passed=$((passed + 1))
      else
        printf "  FAIL %s\n" "$name"
        sed 's/^/         /' "$tmp/$name.err"
        failed=$((failed + 1))
        fail_names="$fail_names $name"
      fi
    done

    total=$(printf '%s\n' "$files" | wc -l | tr -d ' ')
    echo ""
    echo "Ran $total test(s)."

[no-cd]
one TEST:
    #!/usr/bin/env sh

    file="./tests/{{ TEST }}/test.typ"

    if [ ! -f "$file" ]; then
      echo "No such test: {{ TEST }} (expected $file)"
      exit 1
    fi

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    if typst c --root . "$file" "$tmp/out.pdf"; then
      echo "ok {{ TEST }}"
    else
      exit 1
    fi

[no-cd]
list:
    #!/usr/bin/env sh

    find ./tests -type f -iname 'test.typ' -print | sort | while IFS= read -r file; do
      basename "$(dirname "$file")"
    done
