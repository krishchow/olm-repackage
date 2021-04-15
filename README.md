# OLM-Repackage

## Goals

- Repackage an arbitary Crossplane provider as an Operator deployable via OLM
- Minimize changes to the provider, avoid code changes if possible
- Maintain functionality, ideally the operator should be able to integrate with Crossplane

## Components

- `gen_rbac.sh`: This script generates a `rbac.go` file which contains kubebuilder annotations for generating the RBAC resources for the provider. With Crossplane, this responsibility is shifted to the installing Operator, but for OLM we need to generate these at build time.
- `gen_project.sh`: This script is similar to the `gen_rbac`, however, it instead generates our top-level PROJECT file. This file contains metadata about the provider.
  - `PROJECT.boilerplate.txt`: This is used by the `gen_project` script for the initial boilerplate of the PROJECT file.
- `Dockerfile`: We use a custom, minimal Dockerfile to build and run the provider.
- `Makefile`: We also utilize a minimal Makefile to handle the code-generation, build, and deployment steps. Testing steps from the Makefile have been removed.
- `config/`: this directory contains all the required manifests for deploying the provider and setting up the RBAC. This is done through a series of kustomize configurations.

## Workflow

To see an example of building a Operator from a provider can be found in the [provider-ci](https://github.com/redhat-et/provider-ci) repository.
