ver := `dasel -i toml 'package.version' < ../typst.toml | tr -d "'"`

[no-cd]
build:
    typst c --root . --input version={{ ver }} manual/main.typ manual/manual.pdf
    @echo "Built manual/manual.pdf (version {{ ver }})"

[no-cd]
watch:
    typst w --root . --input version={{ ver }} manual/main.typ manual/manual.pdf

[no-cd]
open: build
    open manual/manual.pdf

[no-cd]
clean:
    @if [ -f manual/manual.pdf ]; then \
      rm manual/manual.pdf; \
      echo "Removed manual/manual.pdf"; \
    else \
      echo "Nothing to clean."; \
    fi
