#!/bin/bash

# Cleanup ATM Transaction Producer/Consumer Script
# This script removes all resources created by the pub-sub system

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="kafka"
TOPIC_NAME="atm-transactions"

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --delete-topic     Also delete the atm-transactions topic"
    echo "  --force           Skip confirmation prompts"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 # Remove deployments and configmaps only"
    echo "  $0 --delete-topic  # Remove everything including the topic"
    echo "  $0 --force         # Skip confirmation prompts"
}

# Function to parse command line arguments
parse_arguments() {
    DELETE_TOPIC=false
    FORCE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --delete-topic)
                DELETE_TOPIC=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to confirm action
confirm_action() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}This will remove the following resources:${NC}"
    echo "  - ATM Producer deployment"
    echo "  - ATM Consumer deployment"
    echo "  - Producer ConfigMap"
    echo "  - Consumer ConfigMap"
    
    if [[ "$DELETE_TOPIC" == "true" ]]; then
        echo "  - ATM transactions topic (and all its data)"
    fi
    
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
}

# Function to delete deployments
delete_deployments() {
    print_status "Deleting producer and consumer deployments..."
    
    # Delete producer deployment
    if kubectl get deployment atm-producer -n "$NAMESPACE" &> /dev/null; then
        kubectl delete deployment atm-producer -n "$NAMESPACE"
        print_status "Producer deployment deleted."
    else
        print_warning "Producer deployment not found."
    fi
    
    # Delete consumer deployment
    if kubectl get deployment atm-consumer -n "$NAMESPACE" &> /dev/null; then
        kubectl delete deployment atm-consumer -n "$NAMESPACE"
        print_status "Consumer deployment deleted."
    else
        print_warning "Consumer deployment not found."
    fi
}

# Function to delete configmaps
delete_configmaps() {
    print_status "Deleting ConfigMaps..."
    
    # Delete producer configmap
    if kubectl get configmap atm-producer-config -n "$NAMESPACE" &> /dev/null; then
        kubectl delete configmap atm-producer-config -n "$NAMESPACE"
        print_status "Producer ConfigMap deleted."
    else
        print_warning "Producer ConfigMap not found."
    fi
    
    # Delete consumer configmap
    if kubectl get configmap atm-consumer-config -n "$NAMESPACE" &> /dev/null; then
        kubectl delete configmap atm-consumer-config -n "$NAMESPACE"
        print_status "Consumer ConfigMap deleted."
    else
        print_warning "Consumer ConfigMap not found."
    fi
}

# Function to delete topic
delete_topic() {
    if [[ "$DELETE_TOPIC" != "true" ]]; then
        return
    fi
    
    print_status "Deleting ATM transactions topic..."
    
    # Check if topic exists
    if kubectl run kafka-topic-check --rm -i --image bitnami/kafka:latest --namespace="$NAMESPACE" --restart=Never -- \
        kafka-topics.sh --list --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 | grep -q "$TOPIC_NAME"; then
        
        # Delete the topic
        kubectl run kafka-topic-delete --rm -i --image bitnami/kafka:latest --namespace="$NAMESPACE" --restart=Never -- \
            kafka-topics.sh --delete --topic "$TOPIC_NAME" \
            --bootstrap-server kafka-local.kafka.svc.cluster.local:9092
        
        print_status "Topic '$TOPIC_NAME' deleted."
    else
        print_warning "Topic '$TOPIC_NAME' not found."
    fi
}

# Function to delete Docker images
delete_docker_images() {
    print_status "Checking for Docker images to remove..."
    
    # Check for producer image
    if docker image inspect atm-producer:latest &> /dev/null; then
        print_status "Removing producer Docker image..."
        docker rmi atm-producer:latest
    fi
    
    # Check for consumer image
    if docker image inspect atm-consumer:latest &> /dev/null; then
        print_status "Removing consumer Docker image..."
        docker rmi atm-consumer:latest
    fi
}

# Function to wait for resources to be fully deleted
wait_for_cleanup() {
    print_status "Waiting for resources to be fully deleted..."
    
    # Wait for pods to be deleted
    local timeout=60
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        local pods
        pods=$(kubectl get pods -n "$NAMESPACE" -l "system=kafka-pub-sub" --no-headers 2>/dev/null | wc -l)
        
        if [[ $pods -eq 0 ]]; then
            break
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    if [[ $elapsed -ge $timeout ]]; then
        print_warning "Timeout waiting for pods to be deleted. Some resources may still be cleaning up."
    else
        print_status "All resources cleaned up successfully."
    fi
}

# Function to show cleanup status
show_cleanup_status() {
    print_status "Cleanup Status:"
    echo ""
    
    # Check for remaining resources
    local remaining_pods
    local remaining_configmaps
    
    remaining_pods=$(kubectl get pods -n "$NAMESPACE" -l "system=kafka-pub-sub" --no-headers 2>/dev/null | wc -l)
    remaining_configmaps=$(kubectl get configmaps -n "$NAMESPACE" -l "system=kafka-pub-sub" --no-headers 2>/dev/null | wc -l)
    
    if [[ $remaining_pods -eq 0 && $remaining_configmaps -eq 0 ]]; then
        echo -e "${GREEN}✅ All resources cleaned up successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Some resources may still be cleaning up:${NC}"
        if [[ $remaining_pods -gt 0 ]]; then
            echo "  Pods: $remaining_pods"
        fi
        if [[ $remaining_configmaps -gt 0 ]]; then
            echo "  ConfigMaps: $remaining_configmaps"
        fi
    fi
    
    echo ""
    
    # Show topic status if not deleted
    if [[ "$DELETE_TOPIC" != "true" ]]; then
        echo -e "${BLUE}Topic '$TOPIC_NAME' was preserved.${NC}"
        echo "To delete the topic manually:"
        echo "  kubectl run kafka-topic-delete --rm -i --image bitnami/kafka:latest --namespace=$NAMESPACE --restart=Never -- \\"
        echo "    kafka-topics.sh --delete --topic $TOPIC_NAME \\"
        echo "    --bootstrap-server kafka-local.kafka.svc.cluster.local:9092"
        echo ""
    fi
}

# Function to show recreation commands
show_recreation_commands() {
    echo -e "${BLUE}To recreate the pub-sub system:${NC}"
    echo ""
    echo "Deploy everything:"
    echo "  ./scripts/deploy-pub-sub.sh"
    echo ""
    echo "Or manually:"
    echo "  1. Build images:         docker build -t atm-producer:latest producer/"
    echo "  2. Deploy manifests:     kubectl apply -f manifests/"
    echo "  3. Start producer:       ./scripts/start-producer.sh"
    echo "  4. Start consumer:       ./scripts/start-consumer.sh"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🧹 ATM Transaction Pub-Sub Cleanup${NC}"
    echo -e "${BLUE}===================================${NC}"
    
    parse_arguments "$@"
    confirm_action
    delete_deployments
    delete_configmaps
    delete_topic
    delete_docker_images
    wait_for_cleanup
    show_cleanup_status
    
    echo ""
    echo -e "${GREEN}🎉 Cleanup completed!${NC}"
    echo ""
    show_recreation_commands
}

# Execute main function
main "$@" 