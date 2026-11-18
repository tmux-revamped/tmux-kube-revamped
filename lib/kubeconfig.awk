function unquoted(text, first) {
  sub(/^[[:space:]]+/, "", text)
  sub(/[[:space:]]+$/, "", text)
  first = substr(text, 1, 1)
  if (length(text) >= 2 && (first == "\"" || first == quote) && substr(text, length(text), 1) == first) {
    text = substr(text, 2, length(text) - 2)
  }
  return text
}

function flush() {
  if (entry && name != "") {
    count++
    names[count] = name
    clusters[count] = cluster
    namespaces[count] = namespace
    users[count] = user
  }
  entry = 0
  name = ""
  cluster = ""
  namespace = ""
  user = ""
  inside = 0
  entry_indent = -1
  context_indent = -1
}

function starts_a_key(line, first) {
  first = substr(line, 1, 1)
  return line != "" && first !~ /[[:space:]-]/ && first != hash
}

BEGIN {
  quote = sprintf("%c", 39)
  hash = sprintf("%c", 35)
  entry_indent = -1
  context_indent = -1
  dash = -1
}

/^current-context:/ && current == "" {
  current = $0
  sub(/^current-context:/, "", current)
  current = unquoted(current)
}

/^contexts:/ {
  flush()
  listing = 1
  dash = -1
  next
}

listing && starts_a_key($0) {
  flush()
  listing = 0
}

!listing {
  next
}

{
  line = $0
  indent = match(line, /[^ ]/) - 1
  if (indent < 0) {
    next
  }
  after = substr(line, indent + 2, 1)
  if (substr(line, indent + 1, 1) == "-" && (after == " " || after == "")) {
    if (dash < 0) {
      dash = indent
    }
    if (indent == dash) {
      flush()
      entry = 1
      line = substr(line, 1, indent) " " substr(line, indent + 2)
      indent = match(line, /[^ ]/) - 1
    }
  }
  if (!entry || indent < 0 || !match(substr(line, indent + 1), /^[A-Za-z_-]+:/)) {
    next
  }
  key = substr(line, indent + 1, RLENGTH - 1)
  rest = substr(line, indent + RLENGTH + 1)
  if (entry_indent < 0) {
    entry_indent = indent
  }
  if (indent == entry_indent) {
    inside = (key == "context")
    context_indent = -1
    if (key == "name") {
      name = unquoted(rest)
    }
    next
  }
  if (!inside || indent < entry_indent) {
    next
  }
  if (context_indent < 0) {
    context_indent = indent
  }
  if (indent != context_indent) {
    next
  }
  if (key == "cluster") {
    cluster = unquoted(rest)
  } else if (key == "namespace") {
    namespace = unquoted(rest)
  } else if (key == "user") {
    user = unquoted(rest)
  }
}

END {
  flush()
  if (mode == "list") {
    for (i = 1; i <= count; i++) {
      print names[i]
    }
    exit
  }
  found = 0
  for (i = 1; i <= count && current != ""; i++) {
    if (names[i] == current) {
      found = i
      break
    }
  }
  print current
  print (found ? 1 : 0)
  print (found ? (namespaces[found] == "" ? "default" : namespaces[found]) : "")
  print (found ? clusters[found] : "")
  print (found ? users[found] : "")
}
