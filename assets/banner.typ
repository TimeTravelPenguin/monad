// Repository banner.
//
// Compile to SVG with:
//   typst compile --root . assets/banner.typ assets/banner.svg

#set page(
  width: auto,
  height: auto,
  margin: 1.6em,
  fill: white,
)
#set text(size: 10pt)

#let label(s) = text(size: 7.5pt, fill: luma(110), weight: 500, s)

#grid(
  columns: (auto, auto, auto),
  column-gutter: 1.4em,
  align: horizon,

  // Left column: title + describe-phase DSL
  [
    #text(weight: 800, size: 22pt)[monad]
    #v(-1.5em)
    #text(size: 9.5pt, fill: luma(60))[Lawful monadic DSLs for Typst.]

    #text(
      size: 8pt,
      fill: luma(110),
    )[Describe once #sym.dot.c interpret anywhere.]


    ```typc
    let fetch-users = sig({
      Doc("Fetch users, optionally
          narrowing to active ones.")
      Async()
      Name("fetch_users")
      Param("limit", "int")
      Param("active_only", "bool")
      Returns(("list", "text"))
    })
    ```
  ],

  // Middle: arrow
  text(size: 22pt, fill: luma(160))[#sym.arrow.r],

  // Right column: two interpretations
  grid(
    rows: 2,
    row-gutter: 1em,
    inset: (top: 2em),
    [
      #label[python]
      #v(0.2em)
      ```python
      async def fetch_users(limit: int, active_only: bool) -> list[str]:
          """Fetch users, optionally narrowing to active ones."""
          ...
      ```
    ],

    [
      #label[rust]
      #v(0.2em)
      ```rust
      /// Fetch users, optionally narrowing to active ones.
      async fn fetch_users(limit: i64, active_only: bool) -> Vec<String> {
          todo!()
      }
      ```
    ],
  ),
)
