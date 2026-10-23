# Kubernetes – k3s on OPS-LNX02

k3s is a small, certified Kubernetes distribution that runs as one service. It is enough to practise the
`kubectl` work an operations technician does: deploy, scale, inspect, read logs, and fix pods that will not start.

## 1. Install k3s

On OPS-LNX02. Download the install script, read it, then run it (never pipe an unknown script straight into a shell):

```bash
curl -sfL https://get.k3s.io -o k3s-install.sh
less k3s-install.sh
sudo sh k3s-install.sh --disable traefik
```

`--disable traefik` turns off k3s's built-in ingress controller. It would try to use port 80 on the host,
which nginx on OPS-LNX02 already uses.

Check:

```bash
sudo systemctl status k3s --no-pager
sudo k3s kubectl get nodes
```

Let my own user run `kubectl` without sudo:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER":"$USER" ~/.kube/config
chmod 600 ~/.kube/config
echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
source ~/.bashrc
kubectl get nodes -o wide          # STATUS should be Ready
kubectl get pods -A                # system pods in kube-system
```

## 2. Deploy nginx

```bash
cd ~/operations-technician-simulation/kubernetes
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/nginx-deployment.yaml
kubectl apply -f manifests/nginx-service.yaml

kubectl -n ops-lab get all
kubectl -n ops-lab rollout status deployment/web
curl -I http://localhost:30080/
```

From WS01 or the Windows PC: `http://192.168.100.41:30080/`.

## 3. Scale up and down

```bash
kubectl -n ops-lab scale deployment/web --replicas=5
kubectl -n ops-lab get pods -o wide -w        # watch them start, Ctrl+C to stop
kubectl -n ops-lab scale deployment/web --replicas=1
kubectl -n ops-lab get pods
kubectl -n ops-lab scale deployment/web --replicas=2   # back to the value in the manifest
```

Note: `kubectl scale` changes the live object only. The next `kubectl apply` of the manifest sets it back to 2.
The manifest in git is the source of truth.

## 4. Inspect: logs and describe

```bash
kubectl -n ops-lab get pods
POD=$(kubectl -n ops-lab get pods -l app=web -o jsonpath='{.items[0].metadata.name}')

kubectl -n ops-lab logs "$POD"                 # container output (nginx access/error log)
kubectl -n ops-lab logs -l app=web --tail=20   # last lines from all web pods
kubectl -n ops-lab logs "$POD" --previous      # logs from the last crashed container (if any)

kubectl -n ops-lab describe pod "$POD"         # read the Events section at the bottom first
kubectl -n ops-lab describe deployment web
kubectl -n ops-lab get events --sort-by=.lastTimestamp

kubectl -n ops-lab exec -it "$POD" -- sh       # shell inside the container (exit to leave)
```

## 5. Rollouts

```bash
kubectl -n ops-lab set image deployment/web nginx=nginx:1.27-alpine
kubectl -n ops-lab rollout status deployment/web
kubectl -n ops-lab rollout history deployment/web
kubectl -n ops-lab rollout undo deployment/web
kubectl apply -f manifests/nginx-deployment.yaml      # back to the known good state
```

## 6. Scenario

[scenarios/01-pod-not-starting](scenarios/01-pod-not-starting/) – a deployment change leaves new pods that never become Ready.

## Clean up

```bash
kubectl delete namespace ops-lab        # removes everything in the namespace
# remove k3s completely:
# sudo /usr/local/bin/k3s-uninstall.sh
```

## My results

TODO: k3s version, node status, what I saw when scaling, anything that did not work.
