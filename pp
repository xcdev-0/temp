oc get jobs -n ibm-cpd -o json | jq -r '
.items[]
| select((.status.active // 0) > 0)
| [
    .metadata.name,
    ((.metadata.ownerReferences // []) | map(.name) | join(",")),
    (.status.active // 0),
    (.status.startTime // "-")
  ]
| @tsv
'
