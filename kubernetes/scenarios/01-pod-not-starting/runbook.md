# Runbook – Kubernetes 01 Pod not starting

Run on 2026-11-23. Environment: single-node k3s v1.37.2+k3s1 on `ops-lnx01` (Ubuntu 24.04 in Multipass
on my Mac, arm64), not on OPS-LNX02. Because the scenario scripts only run on `ops-lnx02`, I caused the
Part A fault by hand with `kubectl set image` instead of `break.sh`.

## Scenario

Deploy nginx with two replicas (namespace `ops-lab`, Deployment `web`, NodePort 30080), then roll out an
image tag that does not exist.

Install and deploy:

```text
$ curl -sfL https://get.k3s.io | sudo sh -s - --disable traefik
[INFO]  Using v1.37.2+k3s1 as release
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.37.2%2Bk3s1/k3s-arm64
...
[INFO]  systemd: Starting k3s

$ sudo kubectl get nodes
NAME        STATUS   ROLES           AGE   VERSION
ops-lnx01   Ready    control-plane   6s    v1.37.2+k3s1

$ sudo kubectl apply -f namespace.yaml -f nginx-deployment.yaml -f nginx-service.yaml
namespace/ops-lab created
deployment.apps/web created
service/web created
```

`--disable traefik` keeps k3s's ingress controller off port 80, where the host's own nginx listens.

## Part A – symptoms observed (image tag)

```text
$ sudo kubectl set image deployment/web nginx=nginx:1.27.99-lab -n ops-lab
deployment.apps/web image updated

$ sudo kubectl get pods -n ops-lab
NAME                   READY   STATUS              RESTARTS   AGE
web-544c99b496-b8l97   0/1     ContainerCreating   0          19s
web-544c99b496-w6dc4   0/1     ContainerCreating   0          19s
web-6f6b8d684b-fdxbj   0/1     ErrImagePull        0          5s
```

The middle part of a pod name is the ReplicaSet, i.e. the version: `544c99b496` is the original
`nginx:1.27`, `6f6b8d684b` is the new, broken one.

## Part A – diagnosis steps

```text
$ sudo kubectl describe pod -n ops-lab web-6f6b8d684b-fdxbj | tail -8
  Normal   Scheduled  10s   default-scheduler  Successfully assigned ops-lab/web-6f6b8d684b-fdxbj to ops-lnx01
  Normal   Pulling    9s    kubelet            spec.containers{nginx}: Pulling image "nginx:1.27.99-lab"
  Warning  Failed     9s    kubelet            spec.containers{nginx}: Failed to pull image "nginx:1.27.99-lab": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:1.27.99-lab": failed to resolve reference "docker.io/library/nginx:1.27.99-lab": docker.io/library/nginx:1.27.99-lab: not found
  Warning  Failed     9s    kubelet            spec.containers{nginx}: Error: ErrImagePull
  Normal   BackOff    8s    kubelet            spec.containers{nginx}: Back-off pulling image "nginx:1.27.99-lab"
  Warning  Failed     8s    kubelet            spec.containers{nginx}: Error: ImagePullBackOff
```

The Events read in order: scheduled → pulling → `not found` → `ErrImagePull` (the attempt failed) →
`BackOff` / `ImagePullBackOff` (waiting longer and longer before retrying). With no registry in the
image name, Kubernetes pulls from Docker Hub (`docker.io/library/`).

## Part A – root cause

The image tag `nginx:1.27.99-lab` does not exist in the registry.

## Part A – fix

```text
$ sudo kubectl rollout undo deployment/web -n ops-lab
Warning: resource deployments/web was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/web rolled back
```

The warning matters: the Deployment was created from a manifest file, and `set image` / `rollout undo`
changed it by hand. `rollout undo` is the quick fix during an incident; afterwards the manifest in Git
must hold the correct version, otherwise the next `kubectl apply` can bring the change back.

## Part B – symptoms observed (crash loop)

TODO: not run yet.

## ImagePullBackOff vs CrashLoopBackOff

`ImagePullBackOff`: the container never starts because its image cannot be downloaded (wrong name or
tag, no access to the registry, network/DNS). `CrashLoopBackOff`: the image is fine, the container
starts and then exits again and again (bad config, application error). Part B covers the second.

## Verification

```text
$ sudo kubectl get pods -n ops-lab
NAME                   READY   STATUS    RESTARTS   AGE
web-544c99b496-b8l97   1/1     Running   0          102s
web-544c99b496-w6dc4   1/1     Running   0          102s

$ curl -I http://localhost:30080
HTTP/1.1 200 OK
Server: nginx/1.27.5
```

Both pods are the original version, the broken pod is gone, and the NodePort answers. Port 80 on the
same machine still answers `nginx/1.24.0 (Ubuntu)`: that is the host's apt-installed nginx, while the
container brings its own nginx version.

## Impact (was the site still up during the broken rollout? why?)

Not shown cleanly in this run: I changed the image before the two original pods had finished starting
(they were still `ContainerCreating` while the first `nginx:1.27` image downloaded). Normally a rolling
update keeps the old pods running until new ones are ready, so a bad image should not take the site down.
TODO: repeat with the original pods `Running` first and watch them stay up.

## Time taken

From the pod ages: the broken pod was created about 5 seconds after `set image`. The rollback ran when
the original pods were 44 seconds old, and both were `Running` when I checked again at 102 seconds.

## Lessons learned

TODO: in my own words.
