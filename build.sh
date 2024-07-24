#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

function crd_to_json_schema() {
  local api_version crd_group crd_kind crd_version document input kind

  echo "Processing ${1}..."
  input="input/${1}.yaml"
  curl --silent --show-error --location "${@:2}" > "${input}"

  for document in $(seq 0 $(($(yq ea '[.] | length' "${input}") - 1))); do
    api_version=$(yq "select(document_index == $document).apiVersion" "${input}" | cut -d "/" -f 2)
    kind=$(yq "select(document_index == $document).kind" "${input}")
    crd_kind=$(yq "select(document_index == $document).spec.names.kind" "${input}" | tr '[:upper:]' '[:lower:]')
    crd_group=$(yq "select(document_index == $document).spec.group" "${input}" | cut -d "." -f 1)

    if [[ "${kind}" != CustomResourceDefinition ]]; then
      continue
    fi

    case "${api_version}" in
      v1beta1)
        crd_version=$(yq "select(document_index == $document).spec.version" "${input}" spec.version)
        yq -o=json -P "select(document_index == $document).spec.validation.openAPIV3Schema" "${input}" | write_schema "${crd_kind}-${crd_group}-${crd_version}.json"
        ;;

      v1)
        for crd_version in $(yq "select(document_index == $document).spec.versions.[].name" "${input}"); do
          yq -o=json -P "select(document_index == $document).spec.versions.[] | select(.name == \"${crd_version}\").schema.openAPIV3Schema" "${input}" | write_schema "${crd_kind}-${crd_group}-${crd_version}.json"
        done
        ;;

      *)
        echo "Unknown API version: ${api_version}" >&2
        return 1
        ;;
    esac
  done
}

function write_schema() {
  sponge "master-standalone/${1}"
  jq 'def strictify: . + if .type == "object" and has("properties") then {additionalProperties: false} + {properties: (({} + .properties) | map_values(strictify))} else null end; . * {properties: {spec: .properties.spec | strictify}}' "master-standalone/${1}" | sponge "master-standalone-strict/${1}"
}

crd_to_json_schema actions-runner-controller https://github.com/actions/actions-runner-controller/releases/download/gha-runner-scale-set-0.8.1/actions-runner-controller.yaml
crd_to_json_schema argo-cd https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml
crd_to_json_schema argocd-extensions https://raw.githubusercontent.com/argoproj-labs/argocd-extensions/main/manifests/crds/argoproj.io_argocdextensions.yaml
crd_to_json_schema argo-rollouts https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
crd_to_json_schema aws-load-balancer-controller https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.8.1/v2_8_1_full.yaml
crd_to_json_schema cert-manager https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml
crd_to_json_schema external-secrets https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
crd_to_json_schema istio https://raw.githubusercontent.com/istio/istio/master/manifests/charts/base/crds/crd-all.gen.yaml
crd_to_json_schema istio-operator https://raw.githubusercontent.com/istio/istio/master/manifests/charts/istio-operator/crds/crd-operator.yaml
crd_to_json_schema kyverno https://raw.githubusercontent.com/kyverno/kyverno/main/config/install.yaml
crd_to_json_schema vault-secrets-operator https://raw.githubusercontent.com/ricoberger/vault-secrets-operator/main/config/crd/bases/ricoberger.de_vaultsecrets.yaml
# Karpenter
crd_to_json_schema karpenter-provisioners https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.32.9/pkg/apis/crds/karpenter.sh_provisioners.yaml
crd_to_json_schema karpenter-node-templates https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.32.9/pkg/apis/crds/karpenter.k8s.aws_awsnodetemplates.yaml
crd_to_json_schema karpenter-node-pools https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.32.9/pkg/apis/crds/karpenter.sh_nodepools.yaml
crd_to_json_schema karpenter-node-claims https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.32.9/pkg/apis/crds/karpenter.sh_nodeclaims.yaml
crd_to_json_schema karpenter-ec2-node-classes https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.32.9/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml
# Crossplane
crd_to_json_schema crossplane-functions https://raw.githubusercontent.com/crossplane/docs/master/content/v1.16/api/crds/pkg.crossplane.io_functions.yaml
crd_to_json_schema crossplane-providers https://raw.githubusercontent.com/crossplane/docs/master/content/v1.16/api/crds/pkg.crossplane.io_providers.yaml
crd_to_json_schema crossplane-deploymentruntimeconfigs https://raw.githubusercontent.com/crossplane/docs/master/content/v1.16/api/crds/pkg.crossplane.io_deploymentruntimeconfigs.yaml
crd_to_json_schema provider-upjet-aws-providerconfigs https://raw.githubusercontent.com/crossplane-contrib/provider-upjet-aws/v1.7.0/package/crds/aws.upbound.io_providerconfigs.yaml
crd_to_json_schema crossplane-functions https://raw.githubusercontent.com/crossplane/docs/master/content/v1.16/api/crds/pkg.crossplane.io_functions.yaml
# Kargo
crd_to_json_schema kargo-freights https://raw.githubusercontent.com/akuity/kargo/main/charts/kargo/resources/crds/kargo.akuity.io_freights.yaml
crd_to_json_schema kargo-projects https://raw.githubusercontent.com/akuity/kargo/main/charts/kargo/resources/crds/kargo.akuity.io_projects.yaml
crd_to_json_schema kargo-promotions https://raw.githubusercontent.com/akuity/kargo/main/charts/kargo/resources/crds/kargo.akuity.io_promotions.yaml
crd_to_json_schema kargo-stages https://raw.githubusercontent.com/akuity/kargo/main/charts/kargo/resources/crds/kargo.akuity.io_stages.yaml
crd_to_json_schema kargo-warehouses https://raw.githubusercontent.com/akuity/kargo/main/charts/kargo/resources/crds/kargo.akuity.io_warehouses.yaml