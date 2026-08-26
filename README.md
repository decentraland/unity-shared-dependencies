# ⚠️ This repository has moved

> [!IMPORTANT]
> **Development of this package continues in the [unity-explorer](https://github.com/decentraland/unity-explorer) monorepo**, under [`unity-shared-dependencies/`](https://github.com/decentraland/unity-explorer/tree/dev/unity-shared-dependencies).
>
> - **Do not open PRs or issues here.** All new work happens in unity-explorer.
> - The code was imported into the monorepo as a squashed snapshot of [`facd86e`](https://github.com/decentraland/unity-shared-dependencies/commit/facd86e); this repo remains as the historical archive.
> - In the monorepo, both `Explorer/` and `avatar-preview-renderer/` consume the package via a local `file:../../unity-shared-dependencies` reference — edit it in place there, no git-URL pinning or publishing step.

---

# unity-shared-dependencies

The sole purpose of this repository is to hold a unity package that contains the following content:

- GLTF Importer wrappers
- Custom Shaders
- Wearable utils

This package is a dependency for `unity-renderer` and `asset-bundle-converter`
