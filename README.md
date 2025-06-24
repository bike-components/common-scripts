# common-scripts
Collection of reusable scripts.

## Use-Cases

- Download Script in Deployment Pipeline -

## Guidelines and tips
### Parameters
Scripts should use named parameters to ensure backwards compatibility.

### Download
Use Exact ref in the url to avoid complications between versions.

e.g. Instead of using  `https://raw.githubusercontent.com/bike-components/common-scripts/refs/heads/main/copy-ghcr-to-ecs.sh`
use tags `https://raw.githubusercontent.com/bike-components/common-scripts/refs/tags/v1.0.0/copy-ghcr-to-ecs.sh`