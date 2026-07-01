# procrastivity (Codex)

An [OpenAI Codex CLI](https://developers.openai.com/codex/cli) plugin
marketplace. Sibling of
[procrastivity/claude-plugins](https://github.com/procrastivity/claude-plugins).

## Plugins

| Plugin | Description |
| ------ | ----------- |
| [direnv-session-loader](https://github.com/procrastivity/direnv-session-loader) | Loads the project's direnv `.envrc` at session start (worktree-aware) and wraps shell tool calls with `direnv exec`. |

## Install

### Add the marketplace

```
codex plugin marketplace add procrastivity/codex-plugins
```

Or from within Codex:

```
/plugins
```

### Install a plugin

Pick a plugin from the table above and install it from the `/plugins`
browser, or:

```
codex plugin install <plugin>
```

## How this repo is organized

Codex's marketplace schema only accepts `{source: "local", path: "./..."}`
entries — plugin files must physically live inside the marketplace repo.
This is a schema-level difference from Claude Code, which accepts
`{source: "github", repo: "..."}` and pulls plugin repos at install time.

To keep each plugin's source-of-truth in its own repo (like
[procrastivity/direnv-session-loader](https://github.com/procrastivity/direnv-session-loader)),
this marketplace **mirrors** the Codex-relevant slice of each plugin into
`plugins/<name>/`. The mirror is driven by
`.github/workflows/mirror.yml`, which is fired by a
`repository_dispatch` event when a plugin repo cuts a release.

For the exact slice mirrored per plugin, see
[`scripts/mirror-plugin.sh`](scripts/mirror-plugin.sh).

## Adding a new plugin

1. In the plugin's source repo, add the Codex-side files:
   `.codex-plugin/plugin.json`, `hooks/codex/hooks.json`,
   `scripts/codex/…`, and any shared libs under `scripts/lib/`.
2. Add a plugin entry to
   [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json).
3. Wire the source repo's release script to fire a `mirror-plugin`
   dispatch at `procrastivity/codex-plugins` on tag push (see the
   `contrib/release` script in `direnv-session-loader` for an example).
4. Manually run the mirror workflow once to seed the first version:
   ```
   gh workflow run mirror.yml \
     -R procrastivity/codex-plugins \
     -f plugin=<name> \
     -f source_repo=procrastivity/<name> \
     -f ref=<tag>
   ```

## License

See [LICENSE](LICENSE).
