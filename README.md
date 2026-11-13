# kubernetes-json-schema

A repo to host custom resource definitions and older versions of some resources to be use with `kubeval` and `kubeconform`, called from the `helm-charts` repo.

## Add new schema

Schema's are generated using the `build.sh` script. Schema's are generated based on the CRD YAML. The script downloads the CRD YAML into `input/` folder and then create the JSON schema and store them in the `master-standalone-strict` folder.

Note: `build.sh` has dependency on sponge (brew install sponge).

To regenerate one source only, set `ONLY` to its name, for example `ONLY=kyverno ./build.sh`.

## Kyverno

`build.sh` takes the Kyverno CRDs from a pinned release. Keep that version equal to the Kyverno version in production (`Frameio/gitops` `applicationsets/kyverno/*/Chart.yaml`). When Kyverno is upgraded, change the version in `build.sh` and run `ONLY=kyverno ./build.sh` in the same PR. Without the schemas, kubeconform in gitops fails on new Kyverno kinds such as `ValidatingPolicy` and `MutatingPolicy`.
