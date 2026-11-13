# nim-dotenv - lint .env files. Pure Nim, no dependencies.
# Reports duplicate keys, malformed lines, empty/invalid keys (ERROR) and
# unquoted spaces in values (WARN), each with a line number, then a summary.
import std/[strutils, os, tables, syncio]

proc usage() =
  stderr.writeLine("usage: nim-dotenv <file.env>   (use - to read stdin)")
  quit(2)

# A valid key matches [A-Za-z_][A-Za-z0-9_]*.
proc validKey(k: string): bool =
  if k.len == 0:
    return false
  if k[0] notin {'A'..'Z', 'a'..'z', '_'}:
    return false
  for i in 1 ..< k.len:
    if k[i] notin {'A'..'Z', 'a'..'z', '0'..'9', '_'}:
      return false
  return true

# True when a value has whitespace that is not wrapped in matching quotes.
# The value is trimmed first; a fully quoted value ("..." or '...') never warns.
proc unquotedSpaces(v: string): bool =
  var s = v.strip()
  if s.len >= 2:
    let f = s[0]
    let l = s[^1]
    if (f == '"' and l == '"') or (f == '\'' and l == '\''):
      return false
  for c in s:
    if c == ' ' or c == '\t':
      return true
  return false

proc lint(text: string): tuple[errors: int, warnings: int] =
  var seen = initTable[string, int]()
  var lineno = 0
  var errs = 0
  var warns = 0
  for raw in text.splitLines():
    inc lineno
    var line = raw.strip()
    if line.len == 0 or line.startsWith("#"):
      continue
    # Strip an optional leading `export ` prefix before parsing.
    if line.startsWith("export"):
      let rest = line[6 .. ^1]
      if rest.len > 0 and (rest[0] == ' ' or rest[0] == '\t'):
        line = rest.strip()
    if line.len == 0 or line.startsWith("#"):
      continue
    let eq = line.find('=')
    if eq < 0:
      echo "ERROR line ", lineno, ": no '=' separator: ", line
      inc errs
      continue
    let key = line[0 ..< eq].strip()
    let val = line[eq + 1 .. ^1]
    if key.len == 0:
      echo "ERROR line ", lineno, ": empty key"
      inc errs
      continue
    if not validKey(key):
      echo "ERROR line ", lineno, ": invalid key \"", key,
           "\" (only [A-Za-z_][A-Za-z0-9_]* allowed)"
      inc errs
      continue
    if seen.hasKey(key):
      echo "ERROR line ", lineno, ": duplicate key \"", key,
           "\" (first seen on line ", seen[key], ")"
      inc errs
    else:
      seen[key] = lineno
    if unquotedSpaces(val):
      echo "WARN line ", lineno, ": value of \"", key,
           "\" contains unquoted spaces"
      inc warns
  return (errs, warns)

proc main() =
  let args = commandLineParams()
  if args.len != 1:
    usage()
  let path = args[0]
  var text: string
  if path == "-":
    text = stdin.readAll()
  else:
    if not fileExists(path):
      stderr.writeLine("nim-dotenv: no such file: ", path)
      quit(2)
    text = readFile(path)
  let (errs, warns) = lint(text)
  echo errs, " error(s), ", warns, " warning(s)"
  if errs > 0:
    quit(1)
  quit(0)

main()