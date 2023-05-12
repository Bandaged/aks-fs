
# add secret store csi
helm upgrade \
    --kubeconfig ../build/aks.kubeconfig \
    --install \
    csi-secrets-store \
    secrets-store-csi-driver/secrets-store-csi-driver \
    --namespace kube-system \
    --debug \
    --set=secrets-store-csi-driver.syncSecret.enabled=true \
    --set=syncSecret.enabled=true
