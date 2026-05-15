# devcontainer-features

Custom [Dev Container Features](https://containers.dev/implementors/features/) published to `ghcr.io/stelonld/devcontainer-features`.

## Features

| Feature | Description |
|---|---|
| [zola](src/zola) | Installs the [Zola](https://www.getzola.org/) static site generator |
| [obsidian-export](src/obsidian-export) | Installs [obsidian-export](https://github.com/zoni/obsidian-export) for converting Obsidian vaults to plain markdown |

## Usage

```json
"features": {
  "ghcr.io/stelonld/devcontainer-features/zola:1": {
    "version": "0.22.1"
  },
  "ghcr.io/stelonld/devcontainer-features/obsidian-export:1": {
    "version": "25.3.0"
  }
}
```
