#!/bin/bash

# Stop ATM Transaction Producer Script
# This script stops the producer by scaling down the deployment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="kafka"
DEPLOYMENT_NAME="atm-producer"

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

# Function to check if deployment exists
check_deployment() {
    print_status "Checking if producer deployment exists..."
    
    if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &> /dev/null; then
        print_error "Producer deployment not found."
        exit 1
    fi
    
    print_status "Producer deployment found."
}

# Function to stop producer
stop_producer() {
    print_status "Stopping ATM transaction producer..."
    
    # Get current replica count
    local current_replicas
    current_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    
    if [[ "$current_replicas" -eq 0 ]]; then
        print_warning "Producer is already stopped (replicas: 0)"
        return
    fi
    
    # Scale down to 0 replicas
    kubectl scale deployment "$DEPLOYMENT_NAME" --replicas=0 -n "$NAMESPACE"
    
    # Wait for pods to be terminated
    print_status "Waiting for producer pods to terminate..."
    kubectl wait --for=delete pods -l app=atm-producer -n "$NAMESPACE" --timeout=60s
    
    print_status "Producer stopped successfully."
}

# Function to show producer status
show_producer_status() {
    print_status "Producer Status:"
    echo ""
    
    # Show deployment status
    kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"
    echo ""
    
    # Show pod status
    local pods
    pods=$(kubectl get pods -n "$NAMESPACE" -l app=atm-producer --no-headers 2>/dev/null | wc -l)
    
    if [[ "$pods" -eq 0 ]]; then
        echo "No producer pods running."
    else
        kubectl get pods -n "$NAMESPACE" -l app=atm-producer
    fi
    echo ""
}

# Function to show restart commands
show_restart_commands() {
    echo -e "${BLUE}Restart Commands:${NC}"
    echo ""
    echo "Start producer with default settings:"
    echo "  ./scripts/start-producer.sh"
    echo ""
    echo "Start producer with custom rate:"
    echo "  ./scripts/start-producer.sh -r 10"
    echo ""
    echo "Start producer in burst mode:"
    echo "  ./scripts/start-producer.sh -b"
    echo ""
    echo "Manual restart (scale up):"
    echo "  kubectl scale deployment/$DEPLOYMENT_NAME --replicas=1 -n $NAMESPACE"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🛑 Stopping ATM Transaction Producer${NC}"
    echo -e "${BLUE}====================================${NC}"
    
    check_deployment
    stop_producer
    show_producer_status
    
    echo ""
    echo -e "${GREEN}🎉 Producer stopped successfully!${NC}"
    echo ""
    show_restart_commands
}

# Execute main function
main "$@" 