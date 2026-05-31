# devcontainers

Custom [Dev Container Features](https://containers.dev/implementors/features/) and [Templates](https://containers.dev/implementors/templates/) for use with VS Code Dev Containers.

## Features

Published to `ghcr.io/stelonld/devcontainer-features`.

| Feature | Description |
|---|---|
| [zola](features/zola) | Installs the [Zola](https://www.getzola.org/) static site generator |
| [obsidian-export](features/obsidian-export) | Installs [obsidian-export](https://github.com/zoni/obsidian-export) for converting Obsidian vaults to plain markdown |
| [packer](features/packer) | Installs [HashiCorp Packer](https://www.packer.io/) |
| [opentofu](features/opentofu) | Installs [OpenTofu](https://opentofu.org/), an open-source alternative to Terraform |
| [ansible-lint](features/ansible-lint) | Installs [ansible-lint](https://ansible.readthedocs.io/projects/lint/) into the ansible-core pipx environment |
| [ansible-navigator](features/ansible-navigator) | Installs [ansible-navigator](https://ansible.readthedocs.io/projects/navigator/) into the ansible-core pipx environment |
| [direnv](features/direnv) | Installs [direnv](https://direnv.net/) and configures the shell hook for all users |
| [tflint](features/tflint) | Installs [tflint](https://github.com/terraform-linters/tflint), a linter for OpenTofu/Terraform |

### Usage

```json
"features": {
  "ghcr.io/stelonld/devcontainer-features/zola:1": { "version": "0.22.1" },
  "ghcr.io/stelonld/devcontainer-features/obsidian-export:1": { "version": "25.3.0" },
  "ghcr.io/stelonld/devcontainer-features/packer:1": {},
  "ghcr.io/stelonld/devcontainer-features/tflint:1": {}
}
```

## Templates

Published to `ghcr.io/stelonld/devcontainer-templates`.

| Template | Description |
|---|---|
| [iac-spec](templates/iac-spec) | Full IaC devcontainer — OpenTofu, Packer, Ansible, tflint, ansible-lint. Source for the prebuilt `iac` image. |
| [iac](templates/iac) | IaC devcontainer using the prebuilt image. Faster startup, same tools. |

### Usage

```bash
devcontainer templates apply --template-id ghcr.io/stelonld/devcontainer-templates/iac --workspace-folder .
```

## Prebuilt images

| Image | Description |
|---|---|
| `ghcr.io/stelonld/devcontainers/iac:latest` | Prebuilt image from `iac-spec`. Rebuilt on every change to `templates/iac-spec` and weekly. |
