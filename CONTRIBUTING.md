# Contributing

An Elixir CLI / TUI tool for managing MMOG artifacts — asset upload,
S3 streaming, and artifact lifecycle — built on `ex_ratatui` for the
terminal interface and `req` for HTTP.  Ships as a self-contained
escript binary.  Depends on `taskweft` for planning state and follows
the same red-green-refactor discipline.

Built strictly red-green-refactor: every feature is driven by a failing
test, committed when green, then any cleanup is done with the test
still green.

## Guiding principles

- **RED first, always.** Before writing implementation code write a
  test that fails.  Confirm the failure is for the right reason before
  writing the fix.
- **Error tuples, not exceptions.** All boundary functions return
  `{:ok, value}` / `{:error, reason}`.  `raise` is reserved for
  programmer errors (wrong argument type, missing config at boot).
  HTTP and S3 errors are always `{:error, _}` tuples propagated to
  the caller.
- **TUI state is pure.** Ratatui rendering functions take a model and
  return a new model; they must not perform I/O.  Side effects
  (uploads, API calls) happen in `Task` calls that send messages back
  to the TUI loop.
- **Escript portability.** The compiled binary must run on a machine
  with no Elixir installed.  Avoid runtime dependencies that are not
  bundled — check `mix escript.build` and run the output binary in a
  fresh environment before releasing.
- **Commit every green.** One commit per feature cycle.

## Workflow

```
mix deps.get
mix test                  # run ExUnit suite
mix escript.build         # produce ./artifacts_mmog binary
./artifacts_mmog --help   # smoke test
```

## Design notes

### TUI / async split

Long-running operations (S3 uploads, HTTP calls) are spawned with
`Task.async` and their results sent as messages to the GenServer that
owns TUI state.  The render loop is synchronous and never blocks on
I/O.  This keeps the terminal responsive during large uploads.

### S3 integration

Uploads go through `req` with streaming body support.  Retry logic
lives in a dedicated module; the TUI layer only observes progress
events, never retries directly.  Credentials come from environment
variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
`AWS_ENDPOINT_URL`) — never hardcoded or committed.
