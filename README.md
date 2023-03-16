# kubernetes-json-schema

A repo to host custom resource definitions and older versions of some resources to be use with `kubeval` and `kubeconform`, called from the `helm-charts` repo.

## Add new schema

Schema's are generated using the `build.sh` script. Schema's are generated based on the CRD YAML. The script downloads the CRD YAML into `input/` folder and then create the JSON schema and store them in the `master-standalone-strict` folder.

Note: `build.sh` has dependency on sponge (brew install sponge)
