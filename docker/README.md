# Unison Cloud on Docker Compose

**NOTE:** all paths/files in this documentation assume you are already within the `docker` directory (not the project root).

## Scope and disclaimers

** This is not a production setup.**

This Docker Compose configurations is intended to demonstrate minimalist deployments of unison.cloud in a local environment. It is **not production-ready** but serves testing, development, and demonstration purposes. It provides an easy way to test unison.cloud in your own environment, with the expectation that you might later integrate these learnings into an existing production environment. Specifically, please be aware of the following caveats:

- The secret store (used by [Environment.setValue](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/terms/Environment/setValue) and [Environment.Config.lookup](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/types/Environment/Config)) stores values insecurely and in-memory: **they will not persist when the Vault container is terminated**.
- Your [storage](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/types/Storage), [blobs](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/types/Blobs), and [services](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/types/Services) are persisted only to named Docker volumes on your machine. If your hard drive fails or you perform some overzealous Docker pruning, they are gone forever. The centralized Unison Cloud control plane stores only some metadata like IDs and permissions; it cannot restore your data.


## Prerequisites

### Install Docker

See [instructions on docker.com](https://docs.docker.com/engine/install/).

### Register a cluster

See [instructions](../README.md#register-a-byoc-cluster).

## Configure your cluster

1. Copy [nimbus-secrets-example.json](nimbus-secrets-example.json) to `nimbus-secrets.json`.
2. Replace the `cloudApiToken` value with the token you received when registering your cluster.
3. In `cloudApiInstances.uri`, replace `YOUR_CLUSTER_NAME` with the cluster name that you registered.

Some insecure development credentials (ex: `INSECURE_DEV_TOKEN`) have been provided for the services running on your local cluster. These are fine for local development, so you can leave them for now, but you will want to change them before opening up your cluster outside of your personal computer.

## Run your cluster

Run this `docker compose` command to start up your cluster:

```sh
docker compose --env-file secrets-example.env --env-file .env up --remove-orphans
```

Logs will print to the screen. When you see messages that start with `Starting public HTTP server` from your `unison-cloud-nimbus` instances, your cluster is ready to serve requests!

If you would prefer to run your containers in the background, you can add `--detach` (or `-d`) to the end of the command:

```sh
docker compose --env-file secrets-example.env --env-file .env up --remove-orphans --detach
```

In detached mode logs will not print to the screen and you can use your terminal window to run other commands.

See [Tear down your cluster](#tear-down-your-cluster) when you are ready to stop your cluster.

## Use your new cluster!

Now you can point your [Unison Cloud client](https://share.unison-lang.org/@unison/cloud) to your own cluster to submit batch jobs, deploy services and more!

First you'll need to know the control plane endpoint for your cluster. It has the form `{your_cluster_name}.byoc.unison.cloud` (ex: `alice-homelab.byoc.unison.cloud`).

There are two ways to point your cloud client to your cluster: via an environment variable _or_ with a custom [Cloud.ClientConfig](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/types/Cloud/ClientConfig).

### Configure via environment variable

Set the `UNISON_CLOUD_HOST` environment variable to your cluster control plane endpoint. You could set this in your shell init file (ex: `.bashrc`) or you could just set it in the scope of your `ucm` session:

```sh
UNISON_CLOUD_HOST=alice-homelab.byoc.unison.cloud ucm
```

You can now use [Cloud.run](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/terms/Cloud/run) and it will point to your cluster.

### Configure via Cloud.ClientConfig

Instead of setting the `UNISON_CLOUD_HOST` environment variable, you can programmatically configure your cloud client to point to your cluster. Note that this approach requires using [Cloud.run.withConfig](https://share.unison-lang.org/@unison/cloud/code/releases/20.16.1/latest/terms/Cloud/run/withConfig) instead of `Cloud.run`.

```unison
main : '{IO, Exception} Nat
main = do
  homelabConfig =
    Cloud.ClientConfig.default() |> ClientConfig.host.set (HostName "alice-homelab.byoc.unison.cloud")
  Cloud.run.withConfig homelabConfig do
    Cloud.submit Environment.default() do
      1 + 1
```

## Tear down your cluster

When you are done using your local cluster, you can terminate it. If you ran `docker compose` in attached mode (without the `--detach`/`-d` flag), then you can hit `<ctrl>-c` to stop the running containers.

If you ran `docker compose` in detached mode, then you'll need to run the `down` variant of the `up` command that you previously ran:

```sh
docker compose --env-file secrets-example.env --env-file .env down
```

Even if you ran `docker compose` in attached mode you still may want to run the above `down` command to perform some cleanup that `<ctrl>-c` doesn't trigger like removing stopped containers and the cluster network.
