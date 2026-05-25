#let is-banner = "banner" in sys.inputs

#let opts = (
  banner: (
    // 1280x640px at 300dpi, as recommended by
    // GitHub for social media preview images
    banner-width: 1280in / 300,
    banner-height: 640in / 300,
    margin: 0em,
    text-base: 5pt,
    text-label: 0.625em,
    text-title: 1.83em,
    text-subtitle: 0.8em,
    text-section: 0.67em,
  ),
  default: (
    banner-width: auto,
    banner-height: auto,
    margin: 1.6em,
    text-base: 10pt,
    text-label: 7.5pt,
    text-title: 22pt,
    text-subtitle: 9.5pt,
    text-section: 8pt,
  ),
)

#let opts = if is-banner { opts.banner } else { opts.default }

#set page(
  width: opts.banner-width,
  height: opts.banner-height,
  margin: opts.margin,
  fill: white,
)
#set align(center + horizon)
#set text(size: opts.text-base)

#let label(s) = text(size: opts.text-label, fill: luma(110), weight: 500, s)

#grid(
  columns: (auto, auto, auto),
  column-gutter: 1.4em,
  align: (left + horizon, center + horizon, left + horizon),

  // Left column: title + describe-phase DSL
  [
    #text(weight: 800, size: opts.text-title)[monad]
    #v(-1.5em)
    #text(
      size: opts.text-subtitle,
      fill: luma(60),
    )[Lawful monadic DSLs for Typst.]

    #text(
      size: opts.text-section,
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
  text(size: opts.text-title, fill: luma(160))[#sym.arrow.r],

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
