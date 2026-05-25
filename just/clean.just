_default: examples assets manual

[no-cd]
@manual:
  just --justfile just/manual.just clean 


[no-cd]
examples:
    #!/usr/bin/env sh

    deleted_files=$(find ./examples -type f -iname '*.pdf' -print -delete)

    if [ -n "$deleted_files" ]; then
        echo "Deleted files:"
        printf '%s\n' "$deleted_files" | sed 's/^/  /'
    else
        echo "No examples to delete."
    fi

[no-cd]
assets:
  #!/usr/bin/env sh

  deleted_assets=$(find assets -type f -iname '*.png' -print -delete)

  if [ -n "$deleted_assets" ]; then
      echo "Deleted assets:"
      printf '%s\n' "$deleted_assets" | sed 's/^/  /'
  else
      echo "No assets to delete."
  fi
