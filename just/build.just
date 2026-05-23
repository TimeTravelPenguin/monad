[no-cd]
examples:
    #!/usr/bin/env sh

    files="$(find ./examples -type f -iname '*.typ' -print)"

    if [ -z "$files" ]; then
      echo "No examples to compile."
      exit 0
    fi

    echo "Compiled examples:"

    printf '%s\n' "$files" | while IFS= read -r file; do
      out="${file%.typ}.pdf"

      if typst c --root . "$file" "$out"; then
        printf "  %s\n" "$out"
      fi
    done
