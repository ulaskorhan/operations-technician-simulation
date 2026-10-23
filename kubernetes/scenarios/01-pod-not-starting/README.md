# Kubernetes scenario 01 – pod not starting

**Ticket:** "The deployment of the new web version on OPS-LNX02 never finishes."

Run it in two parts. Do not open the `broken-*.yaml` files before trying.

```bash
cd kubernetes/scenarios/01-pod-not-starting
./check.sh                 # healthy first
./break.sh image-tag       # part A
# troubleshoot, fix, ./check.sh, then ./restore.sh
./break.sh crashloop       # part B
# troubleshoot, fix, ./check.sh, then ./restore.sh
```

> **Note on the original idea.** The plan was "a CrashLoopBackOff caused by a bad image tag".
> In Kubernetes a tag that does not exist gives **ErrImagePull / ImagePullBackOff**: the container never starts,
> so it cannot crash. **CrashLoopBackOff** means the image was pulled, the container started and then exited,
> again and again. That is why there are two parts. Being able to tell the two apart is the point of the exercise.

Commands to start with:

```bash
kubectl -n ops-lab get pods
kubectl -n ops-lab rollout status deployment/web --timeout=30s
kubectl -n ops-lab describe pod <pod-name>        # read Events at the bottom
kubectl -n ops-lab logs <pod-name> --previous     # output of the container that crashed
kubectl -n ops-lab get events --sort-by=.lastTimestamp
kubectl -n ops-lab rollout history deployment/web
```

Fill in [runbook.md](runbook.md) afterwards.
