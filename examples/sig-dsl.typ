#import "../src/lib.typ": free

// A small DSL for describing function signatures, language-agnostic.
// The same DSL program feeds two interpreters: one renders Python source,
// the other Rust.

// ===== type translation =====

#let types = (
  python: (
    text: "str",
    int: "int",
    bool: "bool",
    float: "float",
    list: inner => "list[" + inner + "]",
  ),
  rust: (
    text: "String",
    int: "i64",
    bool: "bool",
    float: "f64",
    list: inner => "Vec<" + inner + ">",
  ),
)

#let render-type(lang, t) = {
  let table = types.at(lang)
  if type(t) == array {
    (table.at(t.first()))(render-type(lang, t.at(1)))
  } else {
    table.at(t, default: t)
  }
}

// ===== DSL builder =====

#let builder = free.make(handlers: (
  Name: name => st => {
    let s = st
    s.insert("name", name)
    (s, none)
  },
  Doc: text => st => {
    let s = st
    s.insert("doc", text)
    (s, none)
  },
  Param: (name, type) => st => {
    let s = st
    s.insert(
      "params",
      st.at("params", default: ()) + ((name: name, type: type),),
    )
    (s, none)
  },
  Returns: type => st => {
    let s = st
    s.insert("returns", type)
    (s, none)
  },
  Async: () => st => {
    let s = st
    s.insert("async", "async ")
    (s, none)
  },
))

#let Name = builder.ops.Name
#let Doc = builder.ops.Doc
#let Param = builder.ops.Param
#let Returns = builder.ops.Returns
#let Async = builder.ops.Async
#let eval = builder.eval
#let sig = body => eval(body).state

// ===== interpreters =====

#let to-python(sig) = {
  let prefix = sig.at("async", default: "")
  let params = sig
    .at("params", default: ())
    .map(
      p => p.name + ": " + render-type("python", p.type),
    )
    .join(", ")

  let head = (
    prefix
      + "def "
      + sig.name
      + "("
      + params
      + ") -> "
      + render-type("python", sig.returns)
      + ":"
  )

  let doc = if "doc" in sig { "    \"\"\"" + sig.doc + "\"\"\"\n" } else { "" }
  head + "\n" + doc + "    ..."
}

#let to-rust(sig) = {
  let prefix = sig.at("async", default: "")
  let params = sig
    .at("params", default: ())
    .map(
      p => p.name + ": " + render-type("rust", p.type),
    )
    .join(", ")

  let doc = if "doc" in sig { "/// " + sig.doc + "\n" } else { "" }

  (
    doc
      + prefix
      + "fn "
      + sig.name
      + "("
      + params
      + ") -> "
      + render-type("rust", sig.returns)
      + " {\n    todo!()\n}"
  )
}

// ===== example program =====

#let fetch-users = sig({
  Doc("Fetch users, optionally narrowing to active ones.")
  Async()
  Name("fetch_users")
  Param("limit", "int")
  Param("active_only", "bool")
  Returns(("list", "text"))
})

== Python rendering

#raw(to-python(fetch-users), lang: "python", block: true)

== Rust rendering

#raw(to-rust(fetch-users), lang: "rust", block: true)
