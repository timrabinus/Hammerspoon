# Repository Guidelines

## Project Structure & Module Organization
Configuration lives at the repository root, with each Lua module focused on a feature (`appLauncher.lua`, `menukeys.lua`, `stack.lua`, etc.). `init.lua` is the entry point; add new modules there so Hammerspoon loads them. Shared helpers stay in `utils.lua`, while keyboard bindings belong in `bindings.lua`. Use `_hammerspoon/` for experiments or sandboxed variants, and keep reusable Spoons under `Spoons/` or `MSpoons/`. Archive older scripts in `Archive/` rather than deleting them outright.

## Build, Test, and Development Commands
Reload the configuration from macOS using the Hammerspoon menu or run `hs -c "hs.reload()"` in a terminal while the app is open. When iterating on hotkeys, call `hs -c "hs.alert('reload')"`, then `hs.reload()` to confirm the UI alerts still render. Toggle `Debug = true` in `init.lua` to enable verbose logging and automatic test runs on reload.

## Coding Style & Naming Conventions
Write Lua with two-space indentation and trailing commas avoided. Use lowerCamelCase for functions (`bindKey`, `asTitleCase`) and SCREAMING_SNAKE_CASE only for constants you want globally visible. Lead every module with a concise comment describing its purpose. Prefer dependency-free modules that expose clear entry functions; limit the use of global variables to shared handles like `hyper` and `shyper` from `utils.lua`.

## Testing Guidelines
Leverage the lightweight harness in `test.lua`. Add new suites with `test("moduleFn", {...})`, naming each case descriptively (`trimWhitespace.removesTabs`). With `Debug = true`, tests run on every reload and report in the Hammerspoon console. Aim to cover both happy-path and edge cases; when behaviour depends on system state, guard tests behind `if Debug then` and document the prerequisites.

## Commit & Pull Request Guidelines
Use present-tense, module-scoped commit summaries such as `feat: add espresso focus` or `fix(stack): handle empty layout`. Bundle related Lua changes together and include console screenshots or short GIFs in PRs when behaviour changes. Reference Jira or GitHub issues with `Refs #123` in the footer. Before opening a PR, confirm you reload cleanly with `Debug = true` so automated tests pass and no console errors appear.
