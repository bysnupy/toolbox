# Cluster up using kind

```console
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-$(uname)-amd64
chmod +x ./kind
sudo mv kind /usr/local/bin

# KinD configuration.
cat > kind.yaml <<EOF
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
- role: control-plane
- role: worker
EOF

kind create cluster --config kind.yaml
```
