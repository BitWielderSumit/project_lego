#!/bin/bash

# TTL Wrapper Script for ATM Transaction Producer
# This script starts the producer and automatically stops it after a specified time

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_RATE=5
DEFAULT_TTL=60

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
    TTL_SECONDS="$DEFAULT_TTL"
    START_ARGS=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--rate)
                RATE="$2"
                START_ARGS+=("-r" "$2")
                shift 2
                ;;
            -b|--burst)
                BURST_MODE="true"
                START_ARGS+=("-b")
                shift
                ;;
            -t|--ttl)
                TTL_SECONDS="$2"
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
    
    # Validate TTL parameter
    if [[ ! "$TTL_SECONDS" =~ ^[0-9]+$ ]] || [[ "$TTL_SECONDS" -eq 0 ]]; then
        print_error "TTL must be a positive integer (seconds)"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --rate RATE     Set message rate (messages per second, default: $DEFAULT_RATE)"
    echo "  -b, --burst         Enable burst mode (send messages as fast as possible)"
    echo "  -t, --ttl TTL       Set time to live in seconds (default: $DEFAULT_TTL)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Start with default rate (5 msg/sec) for 60 seconds"
    echo "  $0 -r 10 -t 30      # Start with 10 msg/sec for 30 seconds"
    echo "  $0 -r 20 -b -t 120  # Start with 20 msg/sec in burst mode for 2 minutes"
    echo ""
    echo "Note: This script will automatically stop the producer after the TTL expires."
}

# Function to cleanup on interruption
cleanup_on_interrupt() {
    print_warning "Interrupted! Stopping producer..."
    "$SCRIPT_DIR/stop-producer.sh" || true
    exit 1
}

# Function to calculate stop time (cross-platform compatible)
calculate_stop_time() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        date -v+${TTL_SECONDS}S '+%Y-%m-%d %H:%M:%S'
    else
        # Linux date command
        date -d "+$TTL_SECONDS seconds" '+%Y-%m-%d %H:%M:%S'
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting ATM Transaction Producer with TTL${NC}"
    echo -e "${BLUE}===========================================${NC}"
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Setup interrupt handler
    trap cleanup_on_interrupt INT TERM
    
    parse_arguments "$@"
    
    # Display configuration
    print_status "Configuration:"
    print_status "  Rate: $RATE messages/second"
    print_status "  Burst mode: $BURST_MODE"
    print_status "  TTL: $TTL_SECONDS seconds ($(($TTL_SECONDS / 60)) minutes)"
    
    STOP_TIME=$(calculate_stop_time)
    print_status "  Estimated stop time: $STOP_TIME"
    
    echo ""
    
    # Start the producer
    print_status "Starting producer..."
    if ! "$SCRIPT_DIR/start-producer.sh" "${START_ARGS[@]}"; then
        print_error "Failed to start producer"
        exit 1
    fi
    
    echo ""
    print_status "Producer started successfully!"
    print_status "Waiting for $TTL_SECONDS seconds before stopping..."
    
    # Show countdown every 10 seconds for TTL > 30 seconds, every 5 seconds for shorter TTL
    if [[ $TTL_SECONDS -gt 30 ]]; then
        COUNTDOWN_INTERVAL=10
    else
        COUNTDOWN_INTERVAL=5
    fi
    
    REMAINING=$TTL_SECONDS
    while [[ $REMAINING -gt 0 ]]; do
        if [[ $REMAINING -le $COUNTDOWN_INTERVAL ]]; then
            # Sleep for the remaining time
            sleep $REMAINING
            REMAINING=0
        else
            # Sleep for the interval
            sleep $COUNTDOWN_INTERVAL
            REMAINING=$((REMAINING - COUNTDOWN_INTERVAL))
            print_status "TTL countdown: $REMAINING seconds remaining"
        fi
    done
    
    echo ""
    print_status "TTL expired! Stopping producer..."
    
    # Stop the producer
    if "$SCRIPT_DIR/stop-producer.sh"; then
        print_status "Producer stopped successfully!"
    else
        print_error "Failed to stop producer - you may need to stop it manually"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 TTL operation completed successfully!${NC}"
}

# Execute main function
main "$@" 