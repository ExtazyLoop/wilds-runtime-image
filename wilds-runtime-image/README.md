# The Wilds — SteamCMD runtime with Python

Prepared for **ExtazyLoop**. This is a Docker build project, not a built image.
No local Docker/Podman engine or WSL is available in the authoring environment,
so the image has NOT been built or tested here. GitHub Actions performs those
checks when you run the included workflow.

The image extends `ghcr.io/ptero-eggs/steamcmd:debian` with the Python runtime
from `python:3.13-slim-bookworm` and explicit shared-library dependencies,
including SQLite. It checks both runtime behavior and inherited startup metadata.
If the upstream Debian release changes, the build stops instead of silently
mixing incompatible releases.

This only adds the backend's prerequisites. It does NOT automatically start the
admin backend, expose its API or implement an in-game F2 panel.

## Build using your GitHub account

1. Sign in as **ExtazyLoop** and create a new repository named
   **wilds-runtime-image**. A public repository makes this simple; upload only
   this build project, never the game directory or server configuration.
2. Extract the supplied ZIP. Upload `Dockerfile`, `smoke.py`, `.dockerignore`
   and `README.md` into the repository root. Do not upload the ZIP itself.
3. Create the workflow file using GitHub's **Add file → Create new file**:
   `.github/workflows/build.yml`. Paste the exact contents of the matching file
   in the ZIP. Creating this file explicitly avoids Windows hiding `.github`.
4. Open **Actions → Build Wilds SteamCMD Python image → Run workflow**.
   Leave **Publish** unchecked for the first validation run. This builds the image
   and checks Python/SQLite and inherited startup settings, without publishing.
5. Once that run passes, run it again with **Publish** checked. This uses GitHub's
   built-in workflow token; no personal password or token needs to be pasted.
6. Open your profile's **Packages**, select **wilds-steamcmd-python**, then its
   package settings. Set package visibility to **Public** if your Wings host has
   no GHCR registry credentials. A public repository does not guarantee a public
   container package. See GitHub's package visibility documentation.

Only after a successful publishing run does this image name exist:

```text
ghcr.io/extazyloop/wilds-steamcmd-python:python3.13
```

The workflow also publishes an immutable-by-convention build-number tag, such as
`build-2`. Prefer that specific tag or its registry digest for a tested deployment;
`python3.13` moves when the workflow publishes again. Build evidence records the
upstream base digests and whether startup metadata stayed unchanged.

## Applying to Pterodactyl

Record the existing image value and back up server files/config using your normal
backup process. Confirm your exact existing image matches the chosen base image;
if it is a provider fork, use that fork as STEAMCMD_IMAGE and review compatibility.
Test on a separate server or during a planned maintenance window.

After publishing, select/enter the GHCR image in the server's Docker image field.
Keep the full existing startup command, EOS arguments, `rcon_watch.sh` and
`LD_PRELOAD` value unchanged. Do not change Nest/Egg settings or trigger a server
reinstallation to install this runtime.

Restart when ready. The diagnostic block already added to `rcon_watch.sh` should
report Python 3.13, SQLite and `Backend requirements: OK`. This proves only the
runtime prerequisites; startup, EOS login, existing plugin and game behavior
still need observation on your server. The image build cannot test your private
plugin because it is not included.

The next stage is a reviewed backend startup and network-access plan. The current
backend binds only to container loopback; simply publishing a Pterodactyl port
will not make the desktop connect. Do not expose RCON or credentials to solve it.

Rollback: restore the previously recorded Docker image and restart during
maintenance. Uploaded server files and the startup command are unchanged by this
build project. Runtime apt dependencies may update libraries; staged game/plugin
testing is required before treating the resulting image as compatible.

## Local Docker alternative

```sh
docker build --platform linux/amd64 -t wilds-steamcmd-python:test .
docker run --rm --entrypoint python3 wilds-steamcmd-python:test /opt/wilds-runtime/smoke.py
```

No secrets belong in the build context. `.dockerignore` allows only Dockerfile
and smoke.py into that context. The image inherits its base entrypoint/CMD,
container user, working directory and stop signal; it contains no replacement
game launcher.

## Primary references

- [Upstream SteamCMD Dockerfile](https://github.com/ptero-eggs/yolks/blob/master/steamcmd/debian/Dockerfile)
- [Official Python Bookworm image source](https://github.com/docker-library/python/blob/master/3.13/slim-bookworm/Dockerfile)
- [Docker documentation for GHCR publishing](https://docs.docker.com/build/ci/github-actions/push-multi-registries/)
- [GitHub Container registry access and visibility](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
