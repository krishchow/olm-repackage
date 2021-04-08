#!/bin/bash

sed -i "s|IMAGE|$IMAGE|g" ./PROJECT.boilerplate.txt
sed -i "s|REPO|$REPO|g" ./PROJECT.boilerplate.txt

cat ./PROJECT.boilerplate.txt

files=$(find ./config/crd/bases/*.yaml -printf "%f\n" | sort)
for value in $files
do
    if [[ -f "config/crd/bases/$value" ]]; then
        name=$(yq eval .spec.names.plural ./config/crd/bases/$value)
        group=$(yq eval .spec.group ./config/crd/bases/$value)
        kind=$(yq eval .spec.names.kind ./config/crd/bases/$value)
        version=$(yq eval .spec.versions[0].name ./config/crd/bases/$value)
        echo "- api:"
        echo "    crdVersion: v1"
        echo "  controller: true"
        echo "  domain: crossplane.io"
        echo "  group: $group"
        echo "  kind: $kind"
        echo "  version: $version"
    fi
done
