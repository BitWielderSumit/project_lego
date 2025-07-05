#!/bin/bash

# Observatory Shutdown Script
# Gracefully removes the monitoring stack with confirmation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="observability"
RELEASE_NAME="prometheus-stack"

# Help function
show_help() {
    echo "🛑 Observatory Shutdown Script"
    echo "Gracefully removes the monitoring stack"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force     - Skip confirmation prompts"
    echo "  --keep-data - Keep persistent volumes (data)"
    echo "  --help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Interactive shutdown"
    echo "  $0 --force          # Force shutdown without confirmation"
    echo "  $0 --keep-data      # Shutdown but keep data volumes"
}

# Default options
FORCE_SHUTDOWN=false
KEEP_DATA=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_SHUTDOWN=true
            shift
            ;;
        --keep-data)
            KEEP_DATA=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo -e "${YELLOW}Use '$0 --help' for usage information${NC}"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}🛑 Observatory Shutdown Sequence${NC}"
echo -e "${CYAN}=================================${NC}"
echo ""

# Check if namespace exists
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}⚠️  Observatory namespace '${NAMESPACE}' not found${NC}"
    echo -e "${YELLOW}   Observatory might already be shut down${NC}"
    exit 0
fi

# Show current status
echo -e "${YELLOW}📋 Current Observatory Status:${NC}"
echo ""
kubectl get pods -n ${NAMESPACE} 2>/dev/null || echo -e "${YELLOW}No pods found${NC}"
echo ""
kubectl get svc -n ${NAMESPACE} 2>/dev/null || echo -e "${YELLOW}No services found${NC}"
echo ""

if [ "$KEEP_DATA" = true ]; then
    echo -e "${BLUE}📊 Persistent Volumes (will be preserved):${NC}"
    kubectl get pvc -n ${NAMESPACE} 2>/dev/null || echo -e "${YELLOW}No persistent volumes found${NC}"
    echo ""
fi

# Confirmation prompt
if [ "$FORCE_SHUTDOWN" = false ]; then
    echo -e "${YELLOW}⚠️  WARNING: This will remove the entire Observatory monitoring stack!${NC}"
    echo ""
    echo -e "${BLUE}This will remove:${NC}"
    echo "  - Prometheus server and all metrics data"
    echo "  - Grafana dashboards and configurations"
    echo "  - AlertManager and alert rules"
    echo "  - All ServiceMonitors and PrometheusRules"
    if [ "$KEEP_DATA" = false ]; then
        echo "  - All persistent volumes and stored data"
    fi
    echo ""
    
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Shutdown cancelled${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}🔄 Initiating shutdown sequence...${NC}"
echo ""

# Step 1: Remove Helm release
echo -e "${YELLOW}📦 Step 1: Removing Helm release...${NC}"
if helm list -n ${NAMESPACE} | grep -q ${RELEASE_NAME}; then
    helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}
    echo -e "${GREEN}✅ Helm release '${RELEASE_NAME}' removed${NC}"
else
    echo -e "${YELLOW}⚠️  Helm release '${RELEASE_NAME}' not found${NC}"
fi

# Step 2: Wait for pods to terminate
echo -e "${YELLOW}⏳ Step 2: Waiting for pods to terminate...${NC}"
kubectl wait --for=delete pods --all -n ${NAMESPACE} --timeout=120s 2>/dev/null || true
echo -e "${GREEN}✅ All pods terminated${NC}"

# Step 3: Remove Custom Resource Definitions (if they exist and are safe to remove)
echo -e "${YELLOW}🔧 Step 3: Checking Custom Resource Definitions...${NC}"
CRD_COUNT=$(kubectl get crd | grep -E "(monitoring\.coreos\.com|prometheus\.io)" | wc -l)
if [ "$CRD_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found ${CRD_COUNT} monitoring-related CRDs${NC}"
    
    if [ "$FORCE_SHUTDOWN" = false ]; then
        read -p "Remove monitoring CRDs? This will affect other Prometheus instances (y/N): " REMOVE_CRDS
        if [ "$REMOVE_CRDS" = "y" ] || [ "$REMOVE_CRDS" = "Y" ]; then
            kubectl get crd | grep -E "(monitoring\.coreos\.com|prometheus\.io)" | awk '{print $1}' | xargs kubectl delete crd 2>/dev/null || true
            echo -e "${GREEN}✅ Monitoring CRDs removed${NC}"
        else
            echo -e "${YELLOW}⚠️  Monitoring CRDs preserved${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Monitoring CRDs preserved (use manual removal if needed)${NC}"
    fi
else
    echo -e "${GREEN}✅ No monitoring CRDs found${NC}"
fi

# Step 4: Remove persistent volumes (if requested)
if [ "$KEEP_DATA" = false ]; then
    echo -e "${YELLOW}🗑️  Step 4: Removing persistent volumes...${NC}"
    PVC_COUNT=$(kubectl get pvc -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
    if [ "$PVC_COUNT" -gt 0 ]; then
        kubectl delete pvc --all -n ${NAMESPACE} 2>/dev/null || true
        echo -e "${GREEN}✅ Removed ${PVC_COUNT} persistent volume(s)${NC}"
    else
        echo -e "${YELLOW}⚠️  No persistent volumes found${NC}"
    fi
else
    echo -e "${BLUE}📊 Step 4: Preserving persistent volumes${NC}"
    PVC_COUNT=$(kubectl get pvc -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
    if [ "$PVC_COUNT" -gt 0 ]; then
        echo -e "${BLUE}   Preserved ${PVC_COUNT} persistent volume(s)${NC}"
        kubectl get pvc -n ${NAMESPACE} 2>/dev/null || true
    fi
fi

# Step 5: Remove namespace
echo -e "${YELLOW}🗂️  Step 5: Removing namespace...${NC}"
kubectl delete namespace ${NAMESPACE} 2>/dev/null || true
echo -e "${GREEN}✅ Namespace '${NAMESPACE}' removal initiated${NC}"

# Step 6: Wait for namespace deletion
echo -e "${YELLOW}⏳ Step 6: Waiting for namespace deletion...${NC}"
while kubectl get namespace ${NAMESPACE} &> /dev/null; do
    echo -e "${YELLOW}   Waiting for namespace deletion...${NC}"
    sleep 5
done
echo -e "${GREEN}✅ Namespace completely removed${NC}"

# Step 7: Clean up any remaining resources
echo -e "${YELLOW}🧹 Step 7: Cleaning up remaining resources...${NC}"

# Remove any dangling ServiceMonitors
DANGLING_SM=$(kubectl get servicemonitor --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.namespace == "observability") | .metadata.name' 2>/dev/null || echo "")
if [ -n "$DANGLING_SM" ]; then
    echo -e "${YELLOW}   Removing dangling ServiceMonitors...${NC}"
    echo "$DANGLING_SM" | xargs -r kubectl delete servicemonitor 2>/dev/null || true
fi

# Remove any dangling PrometheusRules
DANGLING_PR=$(kubectl get prometheusrule --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.namespace == "observability") | .metadata.name' 2>/dev/null || echo "")
if [ -n "$DANGLING_PR" ]; then
    echo -e "${YELLOW}   Removing dangling PrometheusRules...${NC}"
    echo "$DANGLING_PR" | xargs -r kubectl delete prometheusrule 2>/dev/null || true
fi

echo -e "${GREEN}✅ Cleanup completed${NC}"

# Final verification
echo -e "${YELLOW}🔍 Final verification...${NC}"
if kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}⚠️  Namespace still exists (deletion in progress)${NC}"
else
    echo -e "${GREEN}✅ Observatory completely removed${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}🎯 Shutdown Summary${NC}"
echo -e "${CYAN}===================${NC}"
echo ""
echo -e "${GREEN}✅ Observatory shutdown completed successfully!${NC}"
echo ""
echo -e "${BLUE}What was removed:${NC}"
echo "  - Prometheus server and operator"
echo "  - Grafana dashboards and service"
echo "  - AlertManager and alert rules"
echo "  - All ServiceMonitors and PrometheusRules"
echo "  - Observatory namespace"

if [ "$KEEP_DATA" = false ]; then
    echo "  - All persistent volumes and data"
else
    echo ""
    echo -e "${BLUE}What was preserved:${NC}"
    echo "  - Persistent volumes and data"
    echo "  - (Data can be restored with future deployments)"
fi

echo ""
echo -e "${YELLOW}💡 To redeploy the Observatory:${NC}"
echo "   ./observability_hub/scripts/deploy-observatory.sh"
echo ""
echo -e "${CYAN}🌟 Observatory shutdown sequence completed!${NC}" 