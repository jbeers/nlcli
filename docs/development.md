---
title: Development
order: 5
summary: Test, package, and publish nlcli from a checkout.
tags: [development, releases]
---

# Development

The project is intentionally small:

- `nlcli.bxs` contains the application and is compiled into the release binary.
- `nlcli` loads a local `nlcli.env` file and launches MatchBox for source runs.
- `at.bash` provides the optional current-shell integration.
- `install.sh` downloads and verifies release archives.
- `tests/` contains isolated shell-level behavior tests.
- `issues/` records the feature slices behind the implementation.

## Requirements

A source checkout needs [MatchBox](https://github.com/ortus-boxlang/matchbox)
built with these features:

```text
bif-io,bif-crypto,bif-cli,bif-http
```

The launcher searches the usual MatchBox debug and release locations. Set
`MATCHBOX` when using another build.

## Test

Run the complete isolated suite:

```bash
tests/run
```

The test runner gives each test a temporary home, state directory, and
configuration directory. Model calls are stubbed or served by a local test
server; tests do not need an API key or network access.

Run one test directly when narrowing a change:

```bash
MATCHBOX=/path/to/matchbox tests/016.sh
```

## Build a standalone binary

MatchBox compiles `nlcli.bxs` into a native executable:

```bash
mkdir -p package dist
matchbox \
  --target native \
  --no-shaking \
  --strip-source \
  --output package/nlcli \
  nlcli.bxs
chmod +x package/nlcli
package/nlcli --version
tar -czf dist/nlcli-linux-x64.tar.gz -C package nlcli
```

The release workflow performs the same build on Linux and macOS, runs the
shell suite and a packaged-binary smoke test, then publishes archives and
`checksums.txt`. Pushes to `dev` replace the `snapshot` prerelease. Pushes to
`main` publish the version in `box.json`; keep it matched with `VERSION` in
`nlcli.bxs` and bump both before merging a new release.

## Documentation site

Project documentation lives under `docs/` and is built with
[BxSites](https://github.com/ortus-boxlang/bx-sites). Install BxSites and its
runtime dependencies once if needed:

```bash
install-bx-module bx-sites bx-markdown bx-esapi bx-yaml bx-image
```

Then preview or validate the site:

```bash
bxSites serve     # local preview at http://127.0.0.1:8080/
bxSites build     # render docs/ into site/
bxSites lint      # source heading checks
bxSites check     # built link and image checks
```

`site/` is generated output and is not part of the source tree. The checked-in
`baseURL: "/"` keeps local `bxSites serve` assets at the server root; the
delivery workflow replaces it with the project Pages URL for production builds.
It runs the documentation checks and publishes the `main` branch to
[GitHub Pages](https://jbeers.github.io/nlcli/) through the `gh-pages` branch.
For the first deployment, set the repository's Pages source to **Deploy from
a branch**, `gh-pages`, root.
