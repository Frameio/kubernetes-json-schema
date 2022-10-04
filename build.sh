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

crd_to_json_schema actions-runner-controller https://github.com/actions-runner-controller/actions-runner-controller/releases/download/v0.22.0/actions-runner-controller.yaml
crd_to_json_schema argo-cd https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml
crd_to_json_schema argocd-extensions https://raw.githubusercontent.com/argoproj-labs/argocd-extensions/main/manifests/crds/argoproj.io_argocdextensions.yaml
crd_to_json_schema argo-rollouts https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
crd_to_json_schema aws-load-balancer-controller https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.3/v2_4_3_full.yaml
crd_to_json_schema cert-manager https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml
crd_to_json_schema istio https://raw.githubusercontent.com/istio/istio/master/manifests/charts/base/crds/crd-all.gen.yaml
crd_to_json_schema kyverno https://raw.githubusercontent.com/kyverno/kyverno/main/config/install.yaml
crd_to_json_schema vault-secrets-operator https://raw.githubusercontent.com/ricoberger/vault-secrets-operator/main/config/crd/bases/ricoberger.de_vaultsecrets.yaml
