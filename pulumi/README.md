# Pulumi — learning notes and experiments

This folder contains small Pulumi projects used to learn [Pulumi](https://www.pulumi.com/): infrastructure as code (IaC) where you write **real programming languages** (TypeScript, Python, Go, C#, Java, YAML) instead of a domain-specific template language.

## What is Pulumi?

- **IaC**: You declare cloud resources (VPCs, buckets, Kubernetes, etc.) in code; Pulumi creates, updates, and deletes them to match the program.
- **Engine + SDKs**: The Pulumi CLI runs your program, talks to the Pulumi service (or self-hosted backend), and drives providers (AWS, Azure, GCP, Kubernetes, and many others).
- **State**: Pulumi tracks which physical resources map to which logical resources so updates are safe and incremental.
- **Stacks**: Each **stack** is an isolated instance of the same program (e.g. `dev`, `staging`, `prod`) with its own configuration and state.

## Core concepts

| Concept | Meaning |
|--------|---------|
| **Project** | Directory with `Pulumi.yaml` — one deployable program. |
| **Stack** | Named environment (`pulumi stack select`); holds config and state for that deployment. |
| **Program** | Your code that builds a graph of resources (often `index.ts`, `__main__.py`, etc.). |
| **Provider** | Plugin that knows how to talk to a cloud API (e.g. `aws`, `kubernetes`). |
| **Resource** | A managed object (e.g. `aws.s3.Bucket`); has URN, dependencies, and lifecycle. |
| **Outputs** | Values exported from the stack (often secrets or endpoints) usable by other stacks or CI. |

## Typical workflow

1. Install the [Pulumi CLI](https://www.pulumi.com/docs/install/) and log in (`pulumi login` — cloud or file backend).
2. In a project directory: `pulumi new <template>` or copy an example.
3. Choose/configure providers (cloud credentials via env vars or config).
4. `pulumi preview` — see planned changes.
5. `pulumi up` — apply changes.
6. `pulumi destroy` — tear down (useful in learning sandboxes).

## How this repo is organized

- **`examples/`** — numbered or named mini-projects; each should be self-contained with its own `Pulumi.yaml`.
- **`docs/`** (optional) — longer notes, links, or command cheatsheets.

## Official resources

- [Documentation](https://www.pulumi.com/docs/)
- [Tutorials](https://www.pulumi.com/docs/get-started/)
- [Registry (providers + API docs)](https://www.pulumi.com/registry/)

## Safety note

Never commit cloud secrets or private keys. Prefer environment variables, OIDC in CI, or Pulumi secrets (`pulumi config set --secret`).