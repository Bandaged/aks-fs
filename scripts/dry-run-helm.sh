helm upgrade \
    --kubeconfig ../build/aks.kubeconfig \
    test \
    ../charts/test \
    --install \
    -f ../charts/test/values.yaml \
    -f ../charts/test/secrets.yaml \
    -f ../charts/test/values.test.yaml \
    -f ../charts/test/secrets.test.yaml \
    --dry-run \
    --debug
