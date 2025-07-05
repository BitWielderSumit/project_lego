#!/bin/bash

# Start ATM Transaction Consumer Script
# This script starts the consumer with configurable options

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="kafka"
DEPLOYMENT_NAME="atm-consumer"
DEFAULT_FORMAT="detailed"
DEFAULT_OFFSET="latest"

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
    DISPLAY_FORMAT="$DEFAULT_FORMAT"
    OFFSET_RESET="$DEFAULT_OFFSET"
    SHOW_STATS="true"
    STATS_INTERVAL="100"
    STATUS_FILTER=""
    REGION_FILTER=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--format)
                DISPLAY_FORMAT="$2"
                shift 2
                ;;
            -o|--offset)
                OFFSET_RESET="$2"
                shift 2
                ;;
            --no-stats)
                SHOW_STATS="false"
                shift
                ;;
            --stats-interval)
                STATS_INTERVAL="$2"
                shift 2
                ;;
            --status-filter)
                STATUS_FILTER="$2"
                shift 2
                ;;
            --region-filter)
                REGION_FILTER="$2"
                shift 2
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
    echo "  -f, --format FORMAT         Display format: detailed, compact, json (default: $DEFAULT_FORMAT)"
    echo "  -o, --offset OFFSET         Offset reset: earliest, latest (default: $DEFAULT_OFFSET)"
    echo "  --no-stats                  Disable statistics display"
    echo "  --stats-interval INTERVAL   Statistics display interval (default: 100)"
    echo "  --status-filter STATUS      Filter by status codes (comma-separated)"
    echo "  --region-filter REGION      Filter by regions (comma-separated)"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start with default settings"
    echo "  $0 -f compact                        # Start with compact format"
    echo "  $0 -o earliest                       # Start from beginning of topic"
    echo "  $0 --status-filter SUCCESS,FAILED    # Only show successful and failed transactions"
    echo "  $0 --region-filter US-WEST,EU-WEST   # Only show transactions from specific regions"
}

# Function to check if deployment exists
check_deployment() {
    print_status "Checking if consumer deployment exists..."
    
    if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &> /dev/null; then
        print_error "Consumer deployment not found. Please run deploy-pub-sub.sh first."
        exit 1
    fi
    
    print_status "Consumer deployment found."
}

# Function to convert comma-separated string to YAML array
convert_to_yaml_array() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "null"
    else
        echo "[$input]" | sed 's/,/", "/g' | sed 's/\[/["/' | sed 's/\]/"]/'
    fi
}

# Function to update consumer configuration
update_consumer_config() {
    print_status "Updating consumer configuration..."
    print_status "  Display format: $DISPLAY_FORMAT"
    print_status "  Offset reset: $OFFSET_RESET"
    print_status "  Show stats: $SHOW_STATS"
    print_status "  Stats interval: $STATS_INTERVAL"
    
    if [[ -n "$STATUS_FILTER" ]]; then
        print_status "  Status filter: $STATUS_FILTER"
    fi
    
    if [[ -n "$REGION_FILTER" ]]; then
        print_status "  Region filter: $REGION_FILTER"
    fi
    
    # Convert filters to YAML arrays
    local status_filter_yaml
    local region_filter_yaml
    status_filter_yaml=$(convert_to_yaml_array "$STATUS_FILTER")
    region_filter_yaml=$(convert_to_yaml_array "$REGION_FILTER")
    
    # Create the updated configuration
    cat > /tmp/consumer-config.yaml << EOF
kafka:
  bootstrap_servers: "kafka-local.kafka.svc.cluster.local:9092"
  topic: "atm-transactions"
  group_id: "atm-consumer-group"
  auto_offset_reset: "$OFFSET_RESET"

consumer:
  display_format: "$DISPLAY_FORMAT"
  show_stats: $SHOW_STATS
  stats_interval: $STATS_INTERVAL
  filter_by_status: $status_filter_yaml
  filter_by_region: $region_filter_yaml
  filter_by_transaction_type: null
  filter_by_amount_range: null
  max_poll_records: 100
  auto_commit_interval_ms: 1000
  session_timeout_ms: 30000
  heartbeat_interval_ms: 3000
  output_file: null
  include_metadata: false
  alert_on_failed_transactions: true
  alert_threshold_amount: 1000.0
  alert_on_status: ["FAILED", "TIMEOUT", "CARD_BLOCKED"]

logging:
  level: "INFO"
  format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

statistics:
  enable_detailed_stats: true
  track_hourly_stats: false
  track_daily_stats: false
  reset_stats_on_restart: true
EOF

    # Update the ConfigMap
    kubectl create configmap atm-consumer-config \
        --from-file=consumer-config.yaml=/tmp/consumer-config.yaml \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Clean up temp file
    rm -f /tmp/consumer-config.yaml
    
    print_status "Configuration updated successfully."
}

# Function to restart consumer deployment
restart_consumer() {
    print_status "Restarting consumer to apply new configuration..."
    
    # Scale down to 0 and then back up to 1 to ensure config reload
    kubectl scale deployment "$DEPLOYMENT_NAME" --replicas=0 -n "$NAMESPACE"
    kubectl scale deployment "$DEPLOYMENT_NAME" --replicas=1 -n "$NAMESPACE"
    
    # Wait for deployment to be ready
    print_status "Waiting for consumer to be ready..."
    kubectl wait --for=condition=available --timeout=120s deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
    
    print_status "Consumer started successfully."
}

# Function to show consumer status
show_consumer_status() {
    print_status "Consumer Status:"
    echo ""
    
    # Show deployment status
    kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"
    echo ""
    
    # Show pod status
    kubectl get pods -n "$NAMESPACE" -l app=atm-consumer
    echo ""
    
    # Show recent logs
    print_status "Recent logs:"
    kubectl logs --tail=10 deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
}

# Function to show monitoring commands
show_monitoring() {
    echo -e "${BLUE}Monitoring Commands:${NC}"
    echo ""
    echo "Follow logs (recommended):"
    echo "  kubectl logs -f deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
    echo ""
    echo "Check pod status:"
    echo "  kubectl get pods -n $NAMESPACE -l app=atm-consumer"
    echo ""
    echo "Stop consumer:"
    echo "  kubectl scale deployment/$DEPLOYMENT_NAME --replicas=0 -n $NAMESPACE"
    echo ""
    echo "Switch to compact format:"
    echo "  ./scripts/start-consumer.sh -f compact"
    echo ""
    echo "Read from beginning:"
    echo "  ./scripts/start-consumer.sh -o earliest"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting ATM Transaction Consumer${NC}"
    echo -e "${BLUE}==================================${NC}"
    
    parse_arguments "$@"
    check_deployment
    update_consumer_config
    restart_consumer
    show_consumer_status
    
    echo ""
    echo -e "${GREEN}🎉 Consumer started successfully!${NC}"
    echo ""
    show_monitoring
}

# Execute main function
main "$@" 