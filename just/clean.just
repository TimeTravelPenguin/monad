[no-cd]
examples:
    #!/usr/bin/env sh

    deleted_files=$(find ./examples -type f -iname '*.pdf' -print -delete)

    if [ -n "$deleted_files" ]; then
        echo "Deleted files:"
        printf '%s\n' "$deleted_files" | sed 's/^/  /'
    else
        echo "Nothing to delete."
    fi
