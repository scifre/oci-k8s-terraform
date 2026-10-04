#!/usr/bin/env bash
#
# install-addons.sh
#
# Post-apply installer for OKE cluster add-ons: cert-manager, Traefik, and a
# Let's Encrypt ClusterIssuer. Run this AFTER `terraform apply` has created the
# cluster and node pool, and after you have set `api_allowed_cidrs` to include
# this machine's public IP (otherwise the API endpoint on 6443 is unreachable).
#
# What it does:
#   1. Reads live cluster details from `terraform output`.
#   2. Generates a kubeconfig via the OCI CLI.
#   3. Validates that the Kubernetes API is reachable (fails fast if 6443 is blocked).
#   4. Installs cert-manager (with CRDs) via Helm.
#   5. Renders the Traefik override with the live public-subnet and lb-nsg OCIDs
#      and installs Traefik via Helm.
#   6. Applies the Let's Encrypt ClusterIssuer.
#
# Requirements: terraform, oci (OCI CLI), kubectl, helm on PATH.

set -euo pipefail

###############################################################################
# Resolve paths
###############################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd -P)"
ADDONS_DIR="${PROJECT_DIR}/addons"

CERT_MANAGER_CHART="${ADDONS_DIR}/cert-manager"
TRAEFIK_CHART="${ADDONS_DIR}/traefik"
TRAEFIK_OVERRIDE="${TRAEFIK_CHART}/values.override.yaml"
CLUSTER_ISSUER="${ADDONS_DIR}/cluster-issuer/cluster-issuer.yaml"

# Namespaces
CERT_MANAGER_NS="cert-manager"
TRAEFIK_NS="traefik"

# ACME account email for the Let's Encrypt ClusterIssuer. Override via env:
#   ACME_EMAIL="you@example.com" ./scripts/install-addons.sh
ACME_EMAIL="${ACME_EMAIL:-}"

###############################################################################
# Helpers
###############################################################################

log()  { printf '\033[1;34m[addons]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[addons:warn]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[addons:error]\033[0m %s\n' "$*" >&2; }

die() { err "$*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found on PATH."
}

cleanup() {
  if [[ -n "${RENDERED_OVERRIDE:-}" && -f "${RENDERED_OVERRIDE}" ]]; then
    rm -f "${RENDERED_OVERRIDE}"
  fi
  if [[ -n "${RENDERED_ISSUER:-}" && -f "${RENDERED_ISSUER}" ]]; then
    rm -f "${RENDERED_ISSUER}"
  fi
}
trap cleanup EXIT

###############################################################################
# Preflight
###############################################################################

log "Checking required tools..."
require_cmd terraform
require_cmd oci
require_cmd kubectl
require_cmd helm

[[ -d "${CERT_MANAGER_CHART}" ]] || die "cert-manager chart not found at ${CERT_MANAGER_CHART}"
[[ -d "${TRAEFIK_CHART}" ]]      || die "traefik chart not found at ${TRAEFIK_CHART}"
[[ -f "${TRAEFIK_OVERRIDE}" ]]   || die "traefik override not found at ${TRAEFIK_OVERRIDE}"
[[ -f "${CLUSTER_ISSUER}" ]]     || die "cluster-issuer manifest not found at ${CLUSTER_ISSUER}"

[[ -n "${ACME_EMAIL}" ]] || die "ACME_EMAIL is not set. Provide the Let's Encrypt account email, e.g. ACME_EMAIL=\"you@example.com\" ${0}"

###############################################################################
# Read Terraform outputs
###############################################################################

log "Reading Terraform outputs..."

tf_output() {
  # Reads a single output; empty string if missing.
  terraform -chdir="${PROJECT_DIR}" output -raw "$1" 2>/dev/null || true
}

CLUSTER_ID="$(tf_output cluster_id)"
PUBLIC_SUBNET_ID="$(tf_output public_subnet_id)"
LB_NSG_ID="$(tf_output lb_nsg_id)"

# Region is an input variable, not an output; derive it from the cluster OCID
# (…oc1.<region-key>.…) or fall back to the configured OCI CLI region.
REGION="$(tf_output region)"

[[ -n "${CLUSTER_ID}" ]]       || die "terraform output 'cluster_id' is empty. Did you run 'terraform apply'?"
[[ -n "${PUBLIC_SUBNET_ID}" ]] || die "terraform output 'public_subnet_id' is empty."
[[ -n "${LB_NSG_ID}" ]]        || die "terraform output 'lb_nsg_id' is empty."

log "cluster_id       = ${CLUSTER_ID}"
log "public_subnet_id = ${PUBLIC_SUBNET_ID}"
log "lb_nsg_id        = ${LB_NSG_ID}"

###############################################################################
# Generate kubeconfig
###############################################################################

KUBECONFIG_FILE="${PROJECT_DIR}/kubeconfig"
export KUBECONFIG="${KUBECONFIG_FILE}"

log "Generating kubeconfig at ${KUBECONFIG_FILE} ..."

OCI_KUBECONFIG_ARGS=(
  ce cluster create-kubeconfig
  --cluster-id "${CLUSTER_ID}"
  --file "${KUBECONFIG_FILE}"
  --token-version "2.0.0"
  --kube-endpoint "PUBLIC_ENDPOINT"
)
if [[ -n "${REGION}" ]]; then
  OCI_KUBECONFIG_ARGS+=(--region "${REGION}")
fi

oci "${OCI_KUBECONFIG_ARGS[@]}" \
  || die "Failed to create kubeconfig. Check OCI CLI auth and that the cluster is ACTIVE."

chmod 600 "${KUBECONFIG_FILE}" || true

###############################################################################
# Validate API reachability (fails fast if 6443 is blocked by the NSG)
###############################################################################

log "Validating Kubernetes API reachability..."
if ! kubectl version -o json >/dev/null 2>&1; then
  err "Cannot reach the Kubernetes API server."
  err "The public API endpoint listens on TCP 6443 but the k8s-api-endpoint-nsg"
  err "only allows the CIDRs in the Terraform variable 'api_allowed_cidrs'."
  err "Add this machine's public IP to 'api_allowed_cidrs' and re-run"
  err "'terraform apply', then run this script again."
  exit 1
fi
log "API server is reachable."

###############################################################################
# Install cert-manager
###############################################################################

log "Installing cert-manager into namespace '${CERT_MANAGER_NS}' ..."
helm upgrade --install cert-manager "${CERT_MANAGER_CHART}" \
  --namespace "${CERT_MANAGER_NS}" \
  --create-namespace \
  --set crds.enabled=true \
  --wait

log "Waiting for cert-manager webhook to become ready..."
kubectl -n "${CERT_MANAGER_NS}" rollout status deploy/cert-manager-webhook --timeout=180s \
  || warn "cert-manager-webhook rollout status timed out; continuing (issuer apply may need a retry)."

###############################################################################
# Install Traefik (render override with live OCIDs)
###############################################################################

log "Rendering Traefik override with live subnet/NSG OCIDs..."
RENDERED_OVERRIDE="$(mktemp -t traefik-override.XXXXXX.yaml)"

# Substitute placeholder tokens with live Terraform outputs. Using a temp file
# keeps the committed override free of environment-specific OCIDs.
sed \
  -e "s|__PUBLIC_SUBNET_OCID__|${PUBLIC_SUBNET_ID}|g" \
  -e "s|__LB_NSG_OCID__|${LB_NSG_ID}|g" \
  "${TRAEFIK_OVERRIDE}" > "${RENDERED_OVERRIDE}"

# Guard: ensure no placeholders remain.
if grep -q "__PUBLIC_SUBNET_OCID__\|__LB_NSG_OCID__" "${RENDERED_OVERRIDE}"; then
  die "Placeholder substitution failed; tokens still present in rendered override."
fi

log "Installing Traefik into namespace '${TRAEFIK_NS}' ..."
helm upgrade --install traefik "${TRAEFIK_CHART}" \
  --namespace "${TRAEFIK_NS}" \
  --create-namespace \
  -f "${RENDERED_OVERRIDE}" \
  --wait

###############################################################################
# Apply the Let's Encrypt ClusterIssuer
###############################################################################

log "Applying Let's Encrypt ClusterIssuer (email: ${ACME_EMAIL})..."
RENDERED_ISSUER="$(mktemp -t cluster-issuer.XXXXXX.yaml)"

sed -e "s|__ACME_EMAIL__|${ACME_EMAIL}|g" "${CLUSTER_ISSUER}" > "${RENDERED_ISSUER}"

# Guard: ensure the placeholder was substituted.
if grep -q "__ACME_EMAIL__" "${RENDERED_ISSUER}"; then
  die "Placeholder substitution failed; __ACME_EMAIL__ still present in rendered issuer."
fi

kubectl apply -f "${RENDERED_ISSUER}"

###############################################################################
# Summary
###############################################################################

log "Done. Add-ons installed:"
log "  - cert-manager (namespace: ${CERT_MANAGER_NS})"
log "  - traefik      (namespace: ${TRAEFIK_NS})"
log "  - ClusterIssuer 'letsencrypt'"
log ""
log "Next steps:"
log "  1. Find the Traefik LoadBalancer public IP:"
log "       KUBECONFIG=${KUBECONFIG_FILE} kubectl -n ${TRAEFIK_NS} get svc traefik -w"
log "  2. Point your DNS A record at that IP."
log "  3. Ensure Ingress objects use ingressClassName: traefik and the"
log "     'letsencrypt' ClusterIssuer for TLS certificates."
