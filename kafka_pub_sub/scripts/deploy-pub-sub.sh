#!/bin/bash

# ATM Transaction Producer/Consumer Deployment Script
# This script builds Docker images and deploys both producer and consumer to Kubernetes

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="kafka"
PRODUCER_IMAGE="atm-producer:latest"
CONSUMER_IMAGE="atm-consumer:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 ATM Transaction Producer/Consumer Deployment${NC}"
echo -e "${BLUE}=============================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if Kubernetes cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_status "All dependencies are available."
}

# Function to check if Kafka namespace exists
check_namespace() {
    print_status "Checking Kafka namespace..."
    
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_warning "Namespace '$NAMESPACE' does not exist. Creating it..."
        kubectl create namespace "$NAMESPACE"
    else
        print_status "Namespace '$NAMESPACE' already exists."
    fi
}

# Function to build Docker images
build_docker_images() {
    print_status "Building Docker images..."
    
    # Build producer image
    print_status "Building producer image..."
    cd "$PROJECT_DIR/producer"
    docker build -t "$PRODUCER_IMAGE" .
    
    # Build consumer image
    print_status "Building consumer image..."
    cd "$PROJECT_DIR/consumer"
    docker build -t "$CONSUMER_IMAGE" .
    
    print_status "Docker images built successfully."
}

# Function to create topic if it doesn't exist
create_topic() {
    print_status "Checking if ATM transactions topic exists..."
    
    # Check if topic exists
    if kubectl run kafka-topic-check --rm -i --image bitnami/kafka:latest --namespace="$NAMESPACE" --restart=Never -- \
        kafka-topics.sh --list --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 | grep -q "atm-transactions"; then
        print_status "Topic 'atm-transactions' already exists."
    else
        print_status "Creating 'atm-transactions' topic..."
        kubectl run kafka-topic-create --rm -i --image bitnami/kafka:latest --namespace="$NAMESPACE" --restart=Never -- \
            kafka-topics.sh --create --topic atm-transactions \
            --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 \
            --partitions 3 --replication-factor 1 \
            --config cleanup.policy=delete \
            --config retention.ms=604800000 \
            --if-not-exists
        print_status "Topic 'atm-transactions' created successfully."
    fi
}

# Function to deploy to Kubernetes
deploy_to_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
    # Deploy producer
    print_status "Deploying ATM producer..."
    kubectl apply -f "$PROJECT_DIR/manifests/producer-deployment.yaml"
    
    # Deploy consumer
    print_status "Deploying ATM consumer..."
    kubectl apply -f "$PROJECT_DIR/manifests/consumer-deployment.yaml"
    
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/atm-producer -n "$NAMESPACE"
    kubectl wait --for=condition=available --timeout=300s deployment/atm-consumer -n "$NAMESPACE"
    
    print_status "Deployments are ready."
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status:"
    echo ""
    
    # Show pods
    echo -e "${BLUE}Pods:${NC}"
    kubectl get pods -n "$NAMESPACE" -l system=kafka-pub-sub
    echo ""
    
    # Show services
    echo -e "${BLUE}ConfigMaps:${NC}"
    kubectl get configmaps -n "$NAMESPACE" -l system=kafka-pub-sub
    echo ""
    
    # Show topic
    echo -e "${BLUE}Topic Information:${NC}"
    kubectl run kafka-topic-describe --rm -i --image bitnami/kafka:latest --namespace="$NAMESPACE" --restart=Never -- \
        kafka-topics.sh --describe --topic atm-transactions \
        --bootstrap-server kafka-local.kafka.svc.cluster.local:9092
    echo ""
}

# Function to show useful commands
show_usage() {
    echo -e "${BLUE}Useful Commands:${NC}"
    echo ""
    echo "Start producer:"
    echo "  ./scripts/start-producer.sh"
    echo ""
    echo "Start consumer:"
    echo "  ./scripts/start-consumer.sh"
    echo ""
    echo "View producer logs:"
    echo "  kubectl logs -f deployment/atm-producer -n kafka"
    echo ""
    echo "View consumer logs:"
    echo "  kubectl logs -f deployment/atm-consumer -n kafka"
    echo ""
    echo "Scale producer:"
    echo "  kubectl scale deployment/atm-producer --replicas=2 -n kafka"
    echo ""
    echo "Update producer rate:"
    echo "  kubectl patch configmap/atm-producer-config -n kafka --type merge -p '{\"data\":{\"producer-config.yaml\":\"kafka:\\n  bootstrap_servers: \\\"kafka-local.kafka.svc.cluster.local:9092\\\"\\n  topic: \\\"atm-transactions\\\"\\nproducer:\\n  rate: 10\"}}'"
    echo ""
    echo "Clean up:"
    echo "  ./scripts/cleanup-pub-sub.sh"
    echo ""
}

# Main execution
main() {
    print_status "Starting ATM Transaction Producer/Consumer deployment..."
    
    check_dependencies
    check_namespace
    build_docker_images
    create_topic
    deploy_to_kubernetes
    show_status
    
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    show_usage
}

# Execute main function
main "$@" 