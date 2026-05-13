# sdkmanager/

Drop NVIDIA SDK Manager Docker tarballs in this directory.

Download from https://developer.nvidia.com/sdk-manager (NVIDIA Developer
account required). Pick the variant matching your target JetPack family:

| Variant filename                                                  | For    |
| ----------------------------------------------------------------- | ------ |
| `sdkmanager-X.Y.Z.NNNN-Ubuntu_20.04_docker.tar.gz`                | JP5.x  |
| `sdkmanager-X.Y.Z.NNNN-Ubuntu_22.04_docker.tar.gz`                | JP6.x  |
| `sdkmanager-X.Y.Z.NNNN-Ubuntu_24.04_docker.tar.gz` (when shipped) | JP7.x  |

The kit auto-detects which is which by the `Ubuntu_XX.YY` substring in
the filename. Keep NVIDIA's original filename so auto-load Just Works;
otherwise you'll need to load manually with `flashkit sdkm load <file>`.

## Common commands

```sh
flashkit sdkm list           # show local tarballs + which Docker images are loaded
flashkit sdkm load-all       # docker-load every tarball in this directory
flashkit sdkm load <file>    # load one tarball (path, filename, or substring)
```

`flashkit flash <jetpack-profile>` will also auto-load a matching tarball
from this directory if the corresponding Docker image isn't already loaded.

The tarballs themselves are gitignored (large binaries, NVIDIA-licensed) —
only this README is in version control.
