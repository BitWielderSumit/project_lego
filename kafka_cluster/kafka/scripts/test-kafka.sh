#!/bin/bash

# Kafka Test Script
# Tests basic functionality of the Kafka cluster

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
KAFKA_SERVICE="${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092"
TEST_TOPIC="test-topic-$(date +%s)"

echo -e "${BLUE}🧪 Starting Kafka Tests${NC}"

# Check if Kafka is running
echo -e "${YELLOW}🔍 Checking Kafka pods...${NC}"
if ! kubectl get pods -n ${NAMESPACE} | grep -q "Running"; then
    echo -e "${RED}❌ Kafka pods are not running${NC}"
    kubectl get pods -n ${NAMESPACE}
    exit 1
fi
echo -e "${GREEN}✅ Kafka pods are running${NC}"

# Test 1: Create a test topic
echo -e "${YELLOW}📝 Test 1: Creating test topic '${TEST_TOPIC}'${NC}"
kubectl run kafka-test-client --rm -i --tty --image bitnami/kafka:latest --namespace ${NAMESPACE} --restart=Never -- \
    kafka-topics.sh --create --topic ${TEST_TOPIC} --bootstrap-server ${KAFKA_SERVICE} --partitions 1 --replication-factor 1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Topic created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create topic${NC}"
    exit 1
fi

# Test 2: List topics
echo -e "${YELLOW}📝 Test 2: Listing topics${NC}"
kubectl run kafka-test-client --rm -i --tty --image bitnami/kafka:latest --namespace ${NAMESPACE} --restart=Never -- \
    kafka-topics.sh --list --bootstrap-server ${KAFKA_SERVICE}

# Test 3: Send test message
echo -e "${YELLOW}📝 Test 3: Sending test message${NC}"
TEST_MESSAGE="Hello Kafka! $(date)"
echo ${TEST_MESSAGE} | kubectl run kafka-test-client --rm -i --image bitnami/kafka:latest --namespace ${NAMESPACE} --restart=Never -- \
    kafka-console-producer.sh --topic ${TEST_TOPIC} --bootstrap-server ${KAFKA_SERVICE}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Message sent successfully${NC}"
else
    echo -e "${RED}❌ Failed to send message${NC}"
    exit 1
fi

# Test 4: Read test message
echo -e "${YELLOW}📝 Test 4: Reading test message${NC}"
CONSUMED_MESSAGE=$(kubectl run kafka-test-client --rm -i --image bitnami/kafka:latest --namespace ${NAMESPACE} --restart=Never -- \
    timeout 10s kafka-console-consumer.sh --topic ${TEST_TOPIC} --bootstrap-server ${KAFKA_SERVICE} --from-beginning --max-messages 1)

if echo "${CONSUMED_MESSAGE}" | grep -q "Hello Kafka"; then
    echo -e "${GREEN}✅ Message consumed successfully${NC}"
    echo "Consumed: ${CONSUMED_MESSAGE}"
else
    echo -e "${RED}❌ Failed to consume message or wrong message${NC}"
    echo "Consumed: ${CONSUMED_MESSAGE}"
    exit 1
fi

# Test 5: Delete test topic
echo -e "${YELLOW}📝 Test 5: Cleaning up test topic${NC}"
kubectl run kafka-test-client --rm -i --tty --image bitnami/kafka:latest --namespace ${NAMESPACE} --restart=Never -- \
    kafka-topics.sh --delete --topic ${TEST_TOPIC} --bootstrap-server ${KAFKA_SERVICE}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Topic deleted successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to delete topic (might not exist)${NC}"
fi

echo -e "${GREEN}🎉 All Kafka tests passed! Your cluster is working correctly.${NC}"

# Show cluster info
echo -e "${BLUE}📊 Cluster Information:${NC}"
kubectl get pods -n ${NAMESPACE}
echo ""
kubectl get svc -n ${NAMESPACE}
echo ""

echo -e "${BLUE}🔗 Connection Details:${NC}"
echo "Bootstrap Servers: ${KAFKA_SERVICE}"
echo "Namespace: ${NAMESPACE}"
echo "Client Config: kafka/config/client.properties" 