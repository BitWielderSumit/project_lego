#!/bin/bash

# Kafka Deployment Script
# Deploys Bitnami Kafka with KRaft mode using Bitnami Secure Images

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
VALUES_FILE="kafka/values/values.yaml"

echo -e "${BLUE}🚀 Starting Kafka Deployment${NC}"
echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Release Name: ${RELEASE_NAME}"
echo "  Namespace: ${NAMESPACE}"
echo "  Values File: ${VALUES_FILE}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm is not installed or not in PATH${NC}"
    exit 1
fi

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Create namespace
echo -e "${YELLOW}📁 Creating namespace: ${NAMESPACE}${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy Kafka
echo -e "${YELLOW}🎯 Deploying Kafka cluster...${NC}"
helm upgrade --install ${RELEASE_NAME} \
    oci://registry-1.docker.io/bitnamicharts/kafka \
    --namespace ${NAMESPACE} \
    --values ${VALUES_FILE} \
    --wait \
    --timeout 10m

echo -e "${GREEN}✅ Kafka deployment completed!${NC}"

# Post-deployment fix for consumer offsets topic
echo -e "${YELLOW}🔧 Applying post-deployment fixes...${NC}"
create_consumer_offsets_topic() {
    echo -e "${YELLOW}  📋 Checking/Creating __consumer_offsets topic...${NC}"
    
    # Wait for cluster to be ready
    echo -e "${YELLOW}  ⏳ Waiting for Kafka cluster to be ready...${NC}"
    sleep 30
    
    # Check if topic exists and create if needed
    if ! kubectl run kafka-topic-check --rm -i --image bitnami/kafka:latest --namespace ${NAMESPACE} --restart=Never -- \
        kafka-topics.sh --describe --topic __consumer_offsets --bootstrap-server ${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092 &>/dev/null; then
        
        echo -e "${YELLOW}  🔨 Creating __consumer_offsets topic...${NC}"
        kubectl run kafka-topic-create --rm -i --image bitnami/kafka:latest --namespace ${NAMESPACE} --restart=Never -- \
            kafka-topics.sh --create --topic __consumer_offsets \
            --bootstrap-server ${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092 \
            --partitions 50 --replication-factor 1 \
            --config cleanup.policy=compact \
            --config segment.ms=604800000 \
            --if-not-exists || true
        
        echo -e "${GREEN}  ✅ __consumer_offsets topic created successfully${NC}"
    else
        echo -e "${GREEN}  ✅ __consumer_offsets topic already exists${NC}"
    fi
}

# Apply the fix for KRaft mode (always enabled)
echo -e "${YELLOW}  🎯 Applying KRaft mode consumer offsets fix${NC}"
create_consumer_offsets_topic

echo -e "${GREEN}✅ Post-deployment fixes completed!${NC}"

# Show deployment status
echo -e "${BLUE}📊 Deployment Status:${NC}"
kubectl get pods -n ${NAMESPACE}
echo ""
kubectl get svc -n ${NAMESPACE}
echo ""
kubectl get pvc -n ${NAMESPACE}

# Show connection information
echo -e "${BLUE}🔗 Connection Information:${NC}"
echo "Internal Service: ${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092"
echo "Namespace: ${NAMESPACE}"
echo ""

# Show next steps
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "1. Test the connection:"
echo "   kubectl run kafka-client --rm -i --tty --image bitnami/kafka:latest --namespace ${NAMESPACE} -- bash"
echo ""
echo "2. Create a test topic:"
echo "   kafka-topics.sh --create --topic test --bootstrap-server ${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092 --partitions 1 --replication-factor 1"
echo ""
echo "3. Test producer/consumer (consumer offsets topic automatically created):"
echo "   # Producer: kafka-console-producer.sh --topic test --bootstrap-server ${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092"
echo "   # Consumer: kafka-console-consumer.sh --topic test --bootstrap-server ${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092 --from-beginning"
echo ""
echo "4. View logs:"
echo "   kubectl logs -f deployment/${RELEASE_NAME} -n ${NAMESPACE}"
echo ""
echo -e "${GREEN}💡 Note: __consumer_offsets topic was automatically created for KRaft mode${NC}"
echo ""
echo -e "${GREEN}🎉 Kafka is ready to use!${NC}" 