#!/bin/bash

# Kafka Uninstall Script
# Removes Kafka deployment and cleans up resources

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="kafka"
RELEASE_NAME="kafka-local"

echo -e "${BLUE}🗑️  Starting Kafka Cleanup${NC}"

# Confirm deletion
read -p "Are you sure you want to delete the Kafka cluster? This will delete all data! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Aborted by user${NC}"
    exit 1
fi

# Show what will be deleted
echo -e "${YELLOW}📋 Resources to be deleted:${NC}"
kubectl get all -n ${NAMESPACE} 2>/dev/null || echo "No resources found"
echo ""
kubectl get pvc -n ${NAMESPACE} 2>/dev/null || echo "No PVCs found"
echo ""

# Delete Helm release
echo -e "${YELLOW}🗑️  Uninstalling Helm release: ${RELEASE_NAME}${NC}"
if helm list -n ${NAMESPACE} | grep -q ${RELEASE_NAME}; then
    helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}
    echo -e "${GREEN}✅ Helm release deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Helm release not found${NC}"
fi

# Delete PVCs (they might not be deleted automatically)
echo -e "${YELLOW}🗑️  Deleting Persistent Volume Claims...${NC}"
kubectl delete pvc --all -n ${NAMESPACE} 2>/dev/null || echo "No PVCs to delete"

# Wait for pods to terminate
echo -e "${YELLOW}⏳ Waiting for pods to terminate...${NC}"
kubectl wait --for=delete pods --all -n ${NAMESPACE} --timeout=60s 2>/dev/null || echo "Timeout or no pods found"

# Delete namespace
echo -e "${YELLOW}🗑️  Deleting namespace: ${NAMESPACE}${NC}"
kubectl delete namespace ${NAMESPACE} --ignore-not-found=true

echo -e "${GREEN}✅ Kafka cleanup completed!${NC}"

# Verify cleanup
echo -e "${BLUE}🔍 Verification:${NC}"
if kubectl get namespace ${NAMESPACE} 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Namespace still exists (might be terminating)${NC}"
else
    echo -e "${GREEN}✅ Namespace deleted${NC}"
fi

echo -e "${GREEN}🎉 Kafka has been completely removed from your cluster!${NC}" 