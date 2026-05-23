[no-cd]
build:
    typst c --root . manual/main.typ manual/manual.pdf
    @echo "Built manual/manual.pdf"

[no-cd]
watch:
    typst w --root . manual/main.typ manual/manual.pdf

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
