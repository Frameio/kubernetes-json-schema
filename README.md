# kubernetes-json-schema

A repo to host custom resource definitions and older versions of some resources to be use with `kubeval`. 

```bash
kubeval --additional-schema-locations https://raw.githubusercontent.com/Frameio/kubernetes-json-schema/master -d .
```

CRD's currently supported:

- istio
- cronjob/v1beta1
