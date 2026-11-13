<p align="center">
  <img src="assets/banner.svg" width="830" alt="nim-dotenv banner">
</p>
<p align="center">
  <a href="https://github.com/Celine1337/nim-dotenv/releases"><img src="assets/nav-releases.svg" alt="Releases"></a>
  <a href="https://github.com/motdotla/dotenv"><img src="assets/nav-spec.svg" alt="dotenv format"></a>
  <a href="LICENSE"><img src="assets/nav-mit.svg" alt="MIT"></a>
</p>

<img src="assets/section-about.svg" width="830" alt="About">

**nim-dotenv** lints **`.env` files** from the shell and catches the mistakes that silently break configuration: duplicate keys, lines with no `=` separator, empty keys, keys with illegal characters, and values with unquoted spaces. Every problem is reported with its line number as an `ERROR` or a `WARN`, followed by a one-line summary, so it drops straight into CI or a pre-commit hook. It understands `KEY=value`, double- and single-quoted values, `#` comments, blank lines, and an optional leading `export ` prefix.

Why Nim? Because it compiles to a tiny, dependency-free native binary with a real standard library (`strutils`, `tables`) — so a single `main.nim` is a legitimate, fast linting tool, not a toy script. No runtime to install, no package manager, no interpreter startup cost.

<img src="assets/section-features.svg" width="830" alt="Features">

- **Duplicate keys** — a key defined twice is an `ERROR`, with the line it first appeared on.
- **Structural errors** — missing `=` separator, empty key, and keys that violate `[A-Za-z_][A-Za-z0-9_]*` are all flagged with line numbers.
- **Unquoted-space warnings** — `MSG=hello world` warns; `MSG="hello world"` and `MSG='hello world'` do not.
- **Errors vs warnings** — hard problems exit `1`; a bare warning still exits `0`, so CI can gate on real breakage only.
- **dotenv dialect** — `#` comments, blank lines, and a leading `export ` prefix are handled; matching surrounding quotes are stripped for the space check.
- **Stdin support** — pass `-` to lint a stream, e.g. `cat app.env | nim-dotenv -`.
- **Zero dependencies** — one Nim file; builds to a single static-friendly binary.
- **Tested** — a self-contained `test.sh` builds fixtures and asserts exit codes and output.

<img src="assets/section-stack.svg" width="830" alt="Tech stack">

<img src="assets/section-install.svg" width="830" alt="Install">

Requires the [Nim](https://nim-lang.org) compiler (2.x).

```bash
git clone https://github.com/Celine1337/nim-dotenv.git
cd nim-dotenv
./build.sh          # compiles to bin/nim-dotenv
./bin/nim-dotenv app.env
```

Or compile directly:

```bash
nim c -d:release -o:bin/nim-dotenv src/main.nim
```

<img src="assets/section-usage.svg" width="830" alt="Usage">

```bash
nim-dotenv app.env          # lint a file; exit 1 on errors
nim-dotenv -                # lint from stdin
cat app.env | nim-dotenv -
```

```text
$ nim-dotenv broken.env
ERROR line 2: duplicate key "PORT" (first seen on line 1)
ERROR line 3: no '=' separator: this line has no separator
WARN line 4: value of "MSG" contains unquoted spaces
2 error(s), 1 warning(s)
```

Exit codes: `0` clean (warnings allowed), `1` lint errors, `2` bad usage or unreadable file.

<img src="assets/section-license.svg" width="830" alt="License">

MIT — see [LICENSE](LICENSE).