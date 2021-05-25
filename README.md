# OLM-Repackage

## Objectives

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

If we wanted to go through repackaging manually for the `provider-aws`.

1. We checkout our target repository, in this case, that would be:

```bash
$ git clone https://github.com/crossplane/provider-aws
$ cd provider-aws
```

2. Then, we would need to verify that we have Go, `operator-sdk`, `yq` and Docker or `podman`. Additonally, we will need credentials setup for a container registry.
    1. You can find installation instructions for the operator-sdk [here](https://sdk.operatorframework.io/docs/installation/).
    2. You can install the `yq` CLI tool by following the instructions [here](https://github.com/mikefarah/yq).
3. Next, we will need to clone the olm-repackage repository, We then will copy the contents of this `.work` folder into our `provider-aws` folder.


```bash
$ git clone https://github.com/redhat-et/olm-repackage .work
$ cp -r .work/* .
```


4. Now we can build our OLM operator, but first we need to define our image tag, then we can start building the image. This will build all of our manifests, run code generation, and build/push the OCI image.

```bash
$ OPERATOR_IMG="quay.io/$USERNAME/provider-aws:master"
$ make docker-build docker-push IMG=$OPERATOR_IMG
```
  
5. The last step involves building the bundle for our operator. We also need to create our project file, then we will template various field into manifests, by running:

```bash
$ export IMAGE=provider-aws
$ export REPO=crossplane/provider-aws
$ export TAG=master
$ ./gen_project.sh > PROJECT
$ find config \( -type d -name .git -prune \) -o -type f | xargs sed -i "s|IMAGE|$IMAGE|g"
$ find config \( -type d -name .git -prune \) -o -type f | xargs sed -i "s|REPO|$REPO|g"
$ find config \( -type d -name .git -prune \) -o -type f | xargs sed -i "s|TAG|$TAG|g"

```

6. Then, we need to correctly name the ClusterServiceVersion (csv) by running:

```bash
$ mv config/manifests/bases/IMAGE.clusterserviceversion.yaml config/manifests/bases/$IMAGE.clusterserviceversion.yaml
```

7. We can now proceed with creating the bundle, and setting our bundle image tag

```bash
$ make bundle IMG=$OPERATOR_IMG
$ BUNDLE_IMG="quay.io/$USERNAME/provider-aws-bundle:master"
```

8. Last, we can build and push the OCI image with:

```bash
$ make bundle-build BUNDLE_IMG=$BUNDLE_IMG
$ make docker-push IMG=$BUNDLE_IMG
```

## Running the Operator

### Operator-SDK CLI

The easiest way to get started with running the operator is through the Operator-SDK CLI tool. Installation instructions can be found in the [Operator-SDK documentation](https://sdk.operatorframework.io/docs/building-operators/golang/installation/).

### Operator Lifecycle Manager

Additionally, if you are not using an OpenShift cluster, then you will need to install the Operator Lifecycle Manager. Installation instructions can be found in the [Operator Lifecycle Manager documentation](https://olm.operatorframework.io/docs/getting-started/), or it can be installed through the Operator-SDK by running `operator-sdk olm install`

### Run

If both of these steps are met, then you can simply run:

```bash
$ BUNDLE_IMG="quay.io/$USERNAME/provider-aws-bundle:master"
$ operator-sdk run bundle $BUNDLE_IMG
```

This will start the process of spinning up the operator, installing the CRDs and setting up all the RBAC resources.

## Future Work

Some suggestions for future work based on this repository include:

- Integrating OLM repackaging into the CD workflow for existing providers. With minimal changes to the [provider-ci](https://github.com/redhat-et/provider-ci), it should be feasible to target OLM during the github actions for deployment of an arbitary Crossplane provider.
- Automating building historic provider verions. We have defined the steps for repackaging a single version of a provider, now we can go through past releases and repackage them. These could all be exposed as seperate bundles.
- Build provider registries. The next level of abstraction over bundles is the operator registry. Registries are comprised of several bundles. We should have a release process for a registry for certain versions of providers. For example, we could have a provider-registry:master which tracks the most recent version of a curated set of providers.

## Support

This currently no support guarantees for any of the resources in this repository. There are still several steps to get this repository production ready, but it serves to provide a flexible foundation for any future work. Feel free to open an issue or pull request to this repository. At this point it is not recommended that OLM repackaged providers should be used in a production environment.
