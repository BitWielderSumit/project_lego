#!/bin/bash

# Start ATM Transaction Producer Script
# This script starts the producer with specified configuration

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
DEFAULT_RATE=5

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

# Function to parse command line arguments
parse_arguments() {
    RATE="$DEFAULT_RATE"
    BURST_MODE="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--rate)
                RATE="$2"
                shift 2
                ;;
            -b|--burst)
                BURST_MODE="true"
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --rate RATE     Set message rate (messages per second, default: $DEFAULT_RATE)"
    echo "  -b, --burst         Enable burst mode (send messages as fast as possible)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Start with default rate (5 msg/sec)"
    echo "  $0 -r 10            # Start with 10 messages per second"
    echo "  $0 -r 20 -b         # Start with 20 msg/sec in burst mode"
    echo ""
    echo "Note: Use the ttl-wrapper.sh script if you want to automatically stop after a time limit."
}

# Function to check if deployment exists
check_deployment() {
    print_status "Checking if producer deployment exists..."
    
    if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &> /dev/null; then
        print_error "Producer deployment not found. Please run deploy-pub-sub.sh first."
        exit 1
    fi
    
    print_status "Producer deployment found."
}

# Function to update producer configuration
update_producer_config() {
    print_status "Updating producer configuration..."
    print_status "  Rate: $RATE messages/second"
    print_status "  Burst mode: $BURST_MODE"
    
    # Create the updated configuration
    cat > /tmp/producer-config.yaml << EOF
kafka:
  bootstrap_servers: "kafka-local.kafka.svc.cluster.local:9092"
  topic: "atm-transactions"

producer:
  rate: $RATE
  burst_mode: $BURST_MODE
  batch_size: 100
  acks: "all"
  retries: 3
  batch_size_bytes: 16384
  linger_ms: 10
  buffer_memory: 33554432
  compression_type: "snappy"

data_generation:
  num_atms: 100
  regions: ["US-WEST", "US-EAST", "US-CENTRAL", "EU-WEST", "EU-CENTRAL", "APAC"]
  transaction_types:
    WITHDRAWAL: 0.60
    BALANCE_INQUIRY: 0.25
    DEPOSIT: 0.10
    TRANSFER: 0.05
  status_codes:
    SUCCESS: 0.85
    FAILED: 0.08
    TIMEOUT: 0.04
    INSUFFICIENT_FUNDS: 0.02
    CARD_BLOCKED: 0.01
  amount_ranges:
    WITHDRAWAL: [20, 500]
    DEPOSIT: [50, 1000]
    TRANSFER: [100, 2000]
    BALANCE_INQUIRY: [0, 0]
  currencies: ["USD", "EUR", "GBP", "JPY", "CAD"]
  locations:
    - "Downtown Branch"
    - "Mall Center"
    - "Airport Terminal"
    - "University Campus"
    - "Shopping Center"
    - "Bank Branch"
    - "Gas Station"
    - "Grocery Store"
    - "Hotel Lobby"
    - "Train Station"
EOF

    # Update the ConfigMap
    kubectl create configmap atm-producer-config \
        --from-file=producer-config.yaml=/tmp/producer-config.yaml \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Clean up temp file
    rm -f /tmp/producer-config.yaml
    
    print_status "Configuration updated successfully."
}

# Function to restart producer deployment
restart_producer() {
    print_status "Restarting producer to apply new configuration..."
    
    # Scale down to 0 and then back up to 1 to ensure config reload
    kubectl scale deployment "$DEPLOYMENT_NAME" --replicas=0 -n "$NAMESPACE"
    kubectl scale deployment "$DEPLOYMENT_NAME" --replicas=1 -n "$NAMESPACE"
    
    # Wait for deployment to be ready
    print_status "Waiting for producer to be ready..."
    kubectl wait --for=condition=available --timeout=120s deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
    
    print_status "Producer started successfully."
}

# Function to show producer status
show_producer_status() {
    print_status "Producer Status:"
    echo ""
    
    # Show deployment status
    kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"
    echo ""
    
    # Show pod status
    kubectl get pods -n "$NAMESPACE" -l app=atm-producer
    echo ""
    
    # Show recent logs
    print_status "Recent logs:"
    kubectl logs --tail=10 deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
}

# Function to show monitoring commands
show_monitoring() {
    echo -e "${BLUE}Monitoring Commands:${NC}"
    echo ""
    echo "Follow logs:"
    echo "  kubectl logs -f deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
    echo ""
    echo "Check pod status:"
    echo "  kubectl get pods -n $NAMESPACE -l app=atm-producer"
    echo ""
    echo "Stop producer manually:"
    echo "  ./scripts/stop-producer.sh"
    echo ""
    echo "Update rate to 10 msg/sec:"
    echo "  ./scripts/start-producer.sh -r 10"
    echo ""
    echo "Run with TTL (auto-stop after time limit):"
    echo "  ./scripts/ttl-wrapper.sh -r 15 -t 300"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting ATM Transaction Producer${NC}"
    echo -e "${BLUE}==================================${NC}"
    
    parse_arguments "$@"
    check_deployment
    update_producer_config
    restart_producer
    show_producer_status
    
    echo ""
    echo -e "${GREEN}🎉 Producer started successfully!${NC}"
    echo ""
    show_monitoring
}

# Execute main function
main "$@" 