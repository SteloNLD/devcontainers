# devcontainers

Custom [Dev Container Features](https://containers.dev/implementors/features/) and [Templates](https://containers.dev/implementors/templates/) for use with VS Code Dev Containers.

## Features

Published to `ghcr.io/stelonld/devcontainer-features`.

| Feature | Description |
|---|---|
| [zola](features/zola) | Installs the [Zola](https://www.getzola.org/) static site generator |
| [obsidian-export](features/obsidian-export) | Installs [obsidian-export](https://github.com/zoni/obsidian-export) for converting Obsidian vaults to plain markdown |
| [opentofu](features/opentofu) | Installs [OpenTofu](https://opentofu.org/), an open-source alternative to Terraform |
| [packer](features/packer) | Installs [HashiCorp Packer](https://www.packer.io/) |
| [tflint](features/tflint) | Installs [tflint](https://github.com/terraform-linters/tflint), a linter for OpenTofu/Terraform |
| [ansible-lint](features/ansible-lint) | Installs [ansible-lint](https://ansible.readthedocs.io/projects/lint/) into the ansible-core pipx environment |
| [ansible-navigator](features/ansible-navigator) | Installs [ansible-navigator](https://ansible.readthedocs.io/projects/navigator/) as a standalone pipx package. Requires either a local Ansible install or a container runtime (Docker/Podman) for Execution Environment usage. |
| [direnv](features/direnv) | Installs [direnv](https://direnv.net/) and configures the shell hook for all users |

### Usage

```json
"features": {
  "ghcr.io/stelonld/devcontainer-features/opentofu:1": {},
  "ghcr.io/stelonld/devcontainer-features/packer:1": {},
  "ghcr.io/stelonld/devcontainer-features/tflint:1": {},
  "ghcr.io/stelonld/devcontainer-features/direnv:1": {}
}
```

## Templates

Published to `ghcr.io/stelonld/devcontainer-templates`.

| Template | Description |
|---|---|
| [iac-spec](templates/iac-spec) | Full IaC devcontainer — OpenTofu, Packer, Ansible, ansible-lint, ansible-navigator, tflint, direnv, pre-commit, sops. Source for the prebuilt `iac` image. |
| [iac](templates/iac) | IaC devcontainer using the prebuilt image. Faster startup, same tools. |

### Usage

```bash
devcontainer templates apply --template-id ghcr.io/stelonld/devcontainer-templates/iac --workspace-folder .
```

## Prebuilt images

| Image | Description |
|---|---|
| `ghcr.io/stelonld/devcontainers/iac:latest` | Prebuilt image from `iac-spec`. Rebuilt on every change to `templates/iac-spec` or `features/` and weekly. |
