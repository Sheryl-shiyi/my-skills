# Known Runtime Issues

Issues inherent to the RHOAI 3.4 deployment process on fresh OpenShift clusters.

## 1. MaaS Gateway TLS — missing certificate secret

**Recurrence: EVERY fresh cluster**

**Symptom:** `openshift-ai-operator` shows `Degraded`:
```
secret openshift-ingress/maas-default-gateway-tls not found
```

**Why:** The HTTPS MaaS Gateway references a TLS secret that must be provisioned by cert-manager. The Certificate cannot be included in the GitOps repo because the ClusterIssuer name varies by cluster.

**Fix:** Create a cert-manager Certificate using the cluster's existing ClusterIssuer. See `resources/maas-gateway-certificate.yaml` for the template.

---

## 2. Connectivity Link — InstallPlan stuck on Manual approval

**Recurrence: SOMETIMES — only when the cluster has a pre-existing older version of the operator (e.g., RHDP sandbox clusters). Does NOT occur on truly fresh clusters with no pre-installed operators.**

**Symptom:** `connectivity-link-operator` shows `Missing`, subscription status says `RequiresApproval`.

**Why:** OLM sometimes requires manual approval for major version upgrades regardless of the `installPlanApproval: Automatic` setting.

**Fix:**
```bash
# Check if stuck
oc get installplan -n openshift-operators | grep rhcl

# If Manual approval shown, approve it
oc patch installplan <PLAN_NAME> -n openshift-operators --type merge -p '{"spec":{"approved":true}}'
```

---

## 3. ArgoCD retry exhaustion

**Recurrence: LIKELY on most deployments**

**Symptom:** Application shows `OutOfSync` with `operationState.phase: Failed`, but the underlying issue has resolved.

**Why:** 18 operators install simultaneously. Dependency chains (operator install → CRD registration → instance CR creation) take time. ArgoCD's retry limit (5 with exponential backoff) is often exhausted before dependencies are ready.

**Fix:**
```bash
oc patch applications.argoproj.io <APP_NAME> -n openshift-gitops \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```
