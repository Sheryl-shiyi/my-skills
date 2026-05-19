#!/bin/bash
# RHOAI 3.4 Post-Deploy Configuration
# Run these steps AFTER all ArgoCD applications reach Synced/Healthy.
# This script is meant to be read and executed step-by-step by an AI agent,
# NOT run as a single batch script (some steps need verification between them).

set -e

echo "=== Step 1: Create databases ==="

oc exec -n redhat-ods-applications deployment/maas-postgres -- \
  psql -U postgres -c "CREATE DATABASE mlflow_db OWNER maas;"

oc exec -n redhat-ods-applications deployment/maas-postgres -- \
  psql -U postgres -c 'CREATE DATABASE "model-registry" OWNER maas;'

# Verify
oc exec -n redhat-ods-applications deployment/maas-postgres -- \
  psql -U postgres -c "\l"
# Should show: maas_db, mlflow_db, model-registry


echo "=== Step 2: Configure Authorino TLS ==="

oc annotate service authorino-authorino-authorization -n kuadrant-system \
  service.beta.openshift.io/serving-cert-secret-name=authorino-server-cert --overwrite

oc patch authorino authorino -n kuadrant-system --type=merge --patch '{
  "spec": {
    "listener": {
      "tls": {
        "enabled": true,
        "certSecretRef": {
          "name": "authorino-server-cert"
        }
      }
    }
  }
}'

oc -n kuadrant-system set env deployment/authorino \
  SSL_CERT_FILE=/etc/ssl/certs/openshift-service-ca/service-ca-bundle.crt \
  REQUESTS_CA_BUNDLE=/etc/ssl/certs/openshift-service-ca/service-ca-bundle.crt


echo "=== Step 3: Deploy MinIO ==="
# Apply resources/minio.yaml, then:

oc create namespace minio 2>/dev/null || true
# oc apply -f resources/minio.yaml
oc wait --for=condition=Available deployment/minio -n minio --timeout=120s
oc exec -n minio deployment/minio -- mc alias set local http://localhost:9000 minio-admin minio_PASS
oc exec -n minio deployment/minio -- mc mb local/model-registry --ignore-existing


echo "=== Step 4: Create Model Registry ==="
# Apply resources/model-registry.yaml, then verify:

# oc apply -f resources/model-registry.yaml
sleep 30
oc get modelregistries.modelregistry.opendatahub.io -n rhoai-model-registries
# Should show AVAILABLE=True
