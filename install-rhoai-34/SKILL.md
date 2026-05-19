---
name: install-rhoai-34
description: "Install Red Hat OpenShift AI (RHOAI) 3.4 on a fresh OpenShift 4.20+ cluster using the ai-accelerator GitOps repo. Use this skill when the user asks to install, deploy, or set up RHOAI 3.4 on an OpenShift cluster. Trigger on: 'install RHOAI', 'deploy RHOAI 3.4', 'set up OpenShift AI', '安装RHOAI', '部署RHOAI 3.4', '搭建AI平台'."
---

# Install RHOAI 3.4 on OpenShift

Deploy RHOAI 3.4 on a fresh OpenShift 4.20+ cluster via the ai-accelerator GitOps repo. Covers the full lifecycle: GitOps bootstrap → runtime fixes → post-deploy configuration → verification.

## Constants

- **Repo:** `https://github.com/Sheryl-shiyi/ai-accelerator.git`
- **Branch:** `main`
- **Overlay:** `rhoai-stable-3.4-aws-gpu`
- **PostgreSQL password:** `maas_PASS`
- **MinIO password:** `minio_PASS`

## Skill File Structure

```
install-rhoai-34/
├── SKILL.md                          # This file — orchestration and flow control
├── resources/
│   ├── minio.yaml                    # MinIO full deployment manifest
│   ├── maas-gateway-certificate.yaml # cert-manager Certificate template
│   └── model-registry.yaml           # Model Registry CR + secret
├── scripts/
│   └── post-deploy.sh                # Post-deploy steps (databases, Authorino TLS)
└── known-issues.md                   # Runtime issues that WILL recur on every fresh cluster
```

Read the relevant resource files when you reach each phase. Do NOT load them all upfront.

---

## Phase 1: Pre-flight Checks

Verify cluster access and repo state:

```bash
oc whoami                    # must be kube:admin or equivalent
oc version                   # server must be 4.20+
```

If the user is not logged in, ask them to run `! oc login ...` in the prompt.

Then verify the ai-accelerator repo:
1. Confirm the repo is cloned and the `rhoai-stable-3.4-aws-gpu` overlay exists
2. Confirm `clusters/overlays/rhoai-stable-3.4-aws-gpu/kustomization.yaml` has `repoURL` pointing to `https://github.com/Sheryl-shiyi/ai-accelerator.git`
3. Confirm all changes are committed and pushed to `origin/main`

---

## Phase 2: GitOps Bootstrap

Run the bootstrap script:

```bash
./bootstrap.sh --bootstrap_dir=rhoai-stable-3.4-aws-gpu
```

Wait for "GitOps has successfully deployed!" message. Then monitor sync status:

```bash
oc get applications.argoproj.io -n openshift-gitops \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status'
```

> **IMPORTANT:** Always use `applications.argoproj.io`, NOT `applications`. The short form may resolve to `app.k8s.io` and return empty results.

Wait 5-10 minutes for most operators to install. Then proceed to Phase 3 to handle runtime issues.

---

## Phase 3: Runtime Fixes

These issues occur on EVERY fresh cluster deployment — they are not bugs in the code but inherent to the deployment process. Read `known-issues.md` for full details on each issue.

### 3.1 MaaS Gateway TLS certificate

The HTTPS gateway references a TLS secret that doesn't exist yet. Read `resources/maas-gateway-certificate.yaml` and apply it, substituting the cluster's ingress domain and ClusterIssuer name:

```bash
INGRESS_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
ISSUER_NAME=$(oc get certificate -n openshift-ingress -o jsonpath='{.items[0].spec.issuerRef.name}')
```

Then apply the template with these values.

### 3.2 Connectivity Link InstallPlan

Check if the connectivity-link subscription is stuck on `RequiresApproval`:

```bash
oc get installplan -n openshift-operators | grep rhcl
```

If the InstallPlan shows `Manual` approval, approve it:

```bash
oc patch installplan <PLAN_NAME> -n openshift-operators --type merge -p '{"spec":{"approved":true}}'
```

### 3.3 ArgoCD retry exhaustion

If any application shows `operationState.phase: Failed` after retries, re-trigger sync:

```bash
oc patch applications.argoproj.io <APP_NAME> -n openshift-gitops \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

---

## Phase 4: Post-Deploy Configuration

After all ArgoCD applications reach Synced/Healthy (or operationState: Succeeded), run the post-deploy steps.

Read and execute `scripts/post-deploy.sh` step by step:

1. **Create databases** (mlflow_db, model-registry) in the maas-postgres instance
2. **Configure Authorino TLS** (annotate service, patch authorino, set CA env vars)
3. **Deploy MinIO** — read and apply `resources/minio.yaml`, then create buckets
4. **Create Model Registry** — read and apply `resources/model-registry.yaml`

---

## Phase 5: Final Verification

### 5.1 DSC components all ready

```bash
oc get datasciencecluster default-dsc \
  -o jsonpath='{range .status.conditions[?(@.status=="True")]}{.type}{"\n"}{end}'
```

Must include: `Ready`, `KserveReady`, `ModelsAsServiceReady`, `TrainerReady`, `TrustyAIReady`, `ModelRegistryReady`, `WorkbenchesReady`.

### 5.2 Observability stack running

```bash
oc get pods -n redhat-ods-monitoring
```

Should show ~11 pods (alertmanager, collector, perses, prometheus, tempo, thanos-querier).

### 5.3 Print access URLs

```bash
echo "RHOAI Dashboard: https://$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}')"
echo "ArgoCD: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
echo "MinIO Console: https://$(oc get route minio-console -n minio -o jsonpath='{.spec.host}')"
```
