# devcontainers

Custom [Dev Container Features](https://containers.dev/implementors/features/) and [Templates](https://containers.dev/implementors/templates/) for use with VS Code Dev Containers.

## Features

Published to `ghcr.io/stelonld/devcontainer-features`.

| Feature | Description |
|---|---|
| [zola](features/zola) | Installs the [Zola](https://www.getzola.org/) static site generator |
| [obsidian-export](features/obsidian-export) | Installs [obsidian-export](https://github.com/zoni/obsidian-export) for converting Obsidian vaults to plain markdown |
| [opentofu](features/opentofu) | Installs [OpenTofu](https://opentofu.org/), an open-source alternative to Terraform |
| [openbao](features/openbao) | Installs the [OpenBao](https://openbao.org/) CLI (`bao`), the open-source fork of HashiCorp Vault |
| [packer](features/packer) | Installs [HashiCorp Packer](https://www.packer.io/) |
| [tflint](features/tflint) | Installs [tflint](https://github.com/terraform-linters/tflint), a linter for OpenTofu/Terraform |
| [ansible-lint](features/ansible-lint) | Installs [ansible-lint](https://ansible.readthedocs.io/projects/lint/) into the ansible-core pipx environment |
| [ansible-navigator](features/ansible-navigator) | Installs [ansible-navigator](https://ansible.readthedocs.io/projects/navigator/) as a standalone pipx package. Only `ansible-navigator` reaches PATH — `ansible-core` and `ansible-lint` come along as dependencies but stay unexposed, so nothing competes with the Execution Environment. Requires a container runtime (Docker/Podman). |
| [direnv](features/direnv) | Installs [direnv](https://direnv.net/) and configures the shell hook for all users |
| [powershell](features/powershell) | Installs [PowerShell](https://github.com/PowerShell/PowerShell) (`pwsh`) and PSScriptAnalyzer, for the `ms-vscode.PowerShell` extension's linting. Adds ~239 MB (pwsh bundles its own .NET). |

### Usage

```json
"features": {
  "ghcr.io/stelonld/devcontainer-features/opentofu:1": {},
  "ghcr.io/stelonld/devcontainer-features/openbao:1": {},
  "ghcr.io/stelonld/devcontainer-features/packer:1": {},
  "ghcr.io/stelonld/devcontainer-features/tflint:1": {},
  "ghcr.io/stelonld/devcontainer-features/direnv:1": {}
}
```

## Templates

Published to `ghcr.io/stelonld/devcontainer-templates`.

| Template | Description |
|---|---|
| [iac-spec](templates/iac-spec) | Full IaC devcontainer — OpenTofu, OpenBao, Packer, Ansible, ansible-lint, ansible-navigator, tflint, direnv, pre-commit, sops. Source for the prebuilt `iac` image. |
| [iac](templates/iac) | IaC devcontainer using the prebuilt image. Faster startup, same tools. |

### Usage

```bash
devcontainer templates apply --template-id ghcr.io/stelonld/devcontainer-templates/iac --workspace-folder .
```

## Prebuilt images

| Image | Description |
|---|---|
| `ghcr.io/stelonld/devcontainers/iac:latest` | Prebuilt image from `iac-spec`. Rebuilt on every change to `templates/iac-spec` or `features/` and weekly. |

`:latest` is a multi-arch manifest (`linux/amd64` + `linux/arm64`), so Apple
Silicon pulls a native image instead of emulating x86_64. Each arch is built on
its own runner and merged; the per-arch tags (`:latest-linux-amd64`,
`:latest-linux-arm64`) stay in the registry if you need to pin one.

```bash
docker manifest inspect ghcr.io/stelonld/devcontainers/iac:latest \
  | jq -r '.manifests[].platform | .os + "/" + .architecture'
```

## Architectures

Features support `linux/amd64` and `linux/arm64`, selecting downloads by
`uname -m`. Two are slower to install on arm64:

- **ansible-navigator** — `onigurumacffi` has no aarch64 wheel, so it is built
  from source and the toolchain removed again afterwards.
- **obsidian-export** — no prebuilt aarch64 binary, compiled from source.

## Keeping dependencies current

Features do not hardcode tool versions. Each `version` option defaults to
`latest` and resolves the newest stable tag at build time, the same way the
upstream `devcontainers/features` do:

```bash
git ls-remote --tags --refs <repo> | sed 's#.*/tags/##; s#^v##' \
  | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -rV | head -1
```

The `grep` keeps stable tags only, so the alphas, betas, RCs and previews that
opentofu, packer and PowerShell publish can never win. A base image without
`git` falls back to the releases API. Pass an exact version to pin; `proposals`
lists suggestions.

Reproducibility comes from the **image**, not from numbers in these files. The
weekly prebuild rebuilds with current versions, the smoke test execs every
binary on both architectures, and the manifest is only merged if both pass — so
a bad upstream release leaves the previous `:latest` standing.

What is left pinned, and therefore owned by Renovate (`renovate.json`):

| pin | manager |
|---|---|
| `FROM quay.io/fedora/fedora:44` | `dockerfile` |
| `actions/checkout@v6`, `devcontainers/ci@v0.3`, … | `github-actions` |
| feature majors, e.g. `pre-commit:2` | `devcontainer` |

Our own features are excluded: they are referenced by major, so every 1.x
release is picked up at the next build with no file change.

Renovate rather than Dependabot because it is not tied to GitHub — it is an
AGPL Node app supporting GitLab (including self-managed), Gitea, Forgejo,
Bitbucket and Azure DevOps. `renovate.json` is portable; only the runner
changes. Self-hosted, e.g. in GitLab CI:

```yaml
renovate:
  image: ghcr.io/renovatebot/renovate:latest
  script: renovate
  variables:
    RENOVATE_PLATFORM: gitlab
    RENOVATE_ENDPOINT: https://gitlab.example.com/api/v4
    RENOVATE_TOKEN: $RENOVATE_TOKEN     # project/group access token
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

To check what the config sees without touching a remote:

```bash
npx renovate --platform=local --dry-run=lookup
```

## Linting Ansible against the Execution Environment

The collections live in the EE, not in the devcontainer, so anything that lints
with its own ansible-lint sees an empty `ansible_collections` and cannot resolve
collection-qualified modules. `ansible-navigator` runs both inside the EE:

```bash
ansible-navigator lint --ee true          # ansible-lint, in the EE
ansible-navigator exec -- <command>       # anything else, in the EE
```

pre-commit builds an isolated environment per hook, so the stock ansible-lint
hook installs a second ansible-lint with no collections. `language: system` uses
what is already on PATH instead:

```yaml
- repo: local
  hooks:
    - id: ansible-lint-ee
      name: ansible-lint (execution environment)
      language: system
      entry: ansible-navigator lint --ee true --mode stdout
      files: \.(yml|yaml)$
```

That belongs in the repos being linted, not here — this repo only installs the
pre-commit binary.
