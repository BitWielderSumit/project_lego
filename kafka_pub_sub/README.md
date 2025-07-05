# Kafka ATM Transaction Producer/Consumer

This module provides a configurable producer and consumer for ATM transaction messages in Kafka.

## Overview

- **Producer**: Generates realistic ATM transaction messages at configurable rates with optional script-level TTL
- **Consumer**: Consumes and displays ATM transaction messages in real-time

## ATM Transaction Schema

Each ATM transaction message contains:
- `transaction_id`: Unique transaction identifier
- `atm_id`: ATM machine identifier
- `region_id`: Geographic region code
- `amount`: Transaction amount
- `status_code`: Transaction status (SUCCESS, FAILED, TIMEOUT, etc.)
- `user_id`: Masked user identifier
- `card_number`: Masked card number (last 4 digits)
- `transaction_type`: Type of transaction (WITHDRAWAL, BALANCE_INQUIRY, DEPOSIT, etc.)
- `location`: ATM location description
- `currency`: Currency code (USD, EUR, etc.)
- `timestamp`: Transaction timestamp

## Quick Start

### Deploy Producer and Consumer
```bash
# Deploy both producer and consumer
./scripts/deploy-pub-sub.sh

# Start producer with default settings (5 messages/second, no time limit)
./scripts/start-producer.sh

# Start consumer
./scripts/start-consumer.sh
```

### Producer TTL (Time-to-Live) Feature
The producer supports automatic termination after a specified time period using a separate TTL wrapper script. This ensures clean shutdown without pod restarts:

```bash
# Run producer for 60 seconds at 10 messages per second
./scripts/ttl-wrapper.sh -r 10 -t 60

# Run producer for 5 minutes (300 seconds) at default rate
./scripts/ttl-wrapper.sh -t 300

# Run producer for 10 minutes at 20 msg/sec in burst mode
./scripts/ttl-wrapper.sh -r 20 -b -t 600
```

### Configuration

#### Producer Configuration
Edit `config/producer-config.yaml` to customize:
- `rate`: Messages per second (default: 5)
- `topic`: Kafka topic name (default: "atm-transactions")
- `burst_mode`: Enable/disable burst mode for testing

#### Consumer Configuration
Edit `config/consumer-config.yaml` to customize:
- `topic`: Kafka topic name
- `group_id`: Consumer group ID
- `auto_offset_reset`: Where to start consuming (earliest/latest)

## Producer Features

### Rate Control
- Configurable message rate (messages per second)
- Burst mode for maximum throughput testing
- Automatic rate limiting with precise timing

### Time-to-Live (TTL)
- **Wrapper script TTL**: Handled by a separate `ttl-wrapper.sh` script, not the producer process
- **Clean shutdown**: Properly stops the Kubernetes deployment (no pod restarts)
- **Countdown display**: Shows remaining time and estimated stop time
- **Automatic termination**: Calls `stop-producer.sh` when TTL expires
- **Simplified architecture**: Keeps the producer script simple and focused

### Transaction Realism
- 100 ATM IDs across 6 geographic regions
- Weighted transaction type distribution
- Realistic status code distribution
- Variable transaction amounts based on type

## Scripts

- `deploy-pub-sub.sh`: Deploy producer and consumer pods
- `start-producer.sh`: Start message production with options:
  - `-r|--rate`: Messages per second
  - `-b|--burst`: Enable burst mode
- `ttl-wrapper.sh`: Start producer with automatic TTL termination:
  - `-r|--rate`: Messages per second
  - `-b|--burst`: Enable burst mode
  - `-t|--ttl`: Time to live in seconds
- `stop-producer.sh`: Stop message production
- `start-consumer.sh`: Start message consumption
- `cleanup-pub-sub.sh`: Clean up all resources

## Code Updates and Redeployment

When you update the producer or consumer code, you need to rebuild the Docker images and redeploy them to Kubernetes.

### Manual Redeployment Steps

1. **Rebuild the Docker images:**
   ```bash
   # Rebuild producer image
   docker build -t atm-producer:latest producer/
   
   # Rebuild consumer image (if updated)
   docker build -t atm-consumer:latest consumer/
   ```

2. **Redeploy to Kubernetes:**
   ```bash
   # Method 1: Use the deployment script (recommended)
   ./scripts/deploy-pub-sub.sh
   
   # Method 2: Manual kubectl commands
   kubectl delete deployment atm-producer -n kafka
   kubectl delete deployment atm-consumer -n kafka
   kubectl apply -f manifests/producer-deployment.yaml
   kubectl apply -f manifests/consumer-deployment.yaml
   ```

3. **Verify deployment:**
   ```bash
   # Check pod status
   kubectl get pods -n kafka
   
   # Check logs
   kubectl logs -f deployment/atm-producer -n kafka
   kubectl logs -f deployment/atm-consumer -n kafka
   ```

### Quick Redeployment Commands

```bash
# Complete rebuild and redeploy (one-liner)
docker build -t atm-producer:latest producer/ && docker build -t atm-consumer:latest consumer/ && ./scripts/deploy-pub-sub.sh

# Producer only
docker build -t atm-producer:latest producer/ && kubectl delete deployment atm-producer -n kafka && kubectl apply -f manifests/producer-deployment.yaml

# Consumer only
docker build -t atm-consumer:latest consumer/ && kubectl delete deployment atm-consumer -n kafka && kubectl apply -f manifests/consumer-deployment.yaml
```

### Important Notes

- **Always rebuild Docker images** after code changes
- **Use `imagePullPolicy: Never`** in deployment manifests for local development
- **Check pod status** after redeployment to ensure successful startup
- **Configuration changes** (YAML files) can be applied without rebuilding images:
  ```bash
  kubectl apply -f manifests/producer-deployment.yaml
  kubectl apply -f manifests/consumer-deployment.yaml
  ```

## Monitoring

Both producer and consumer pods log their activities. Use:
```bash
# View producer logs
kubectl logs -f deployment/atm-producer -n kafka

# View consumer logs
kubectl logs -f deployment/atm-consumer -n kafka
```

## Examples

### Basic Usage
```bash
# Start with defaults (5 msg/sec, no time limit)
./scripts/start-producer.sh

# High-rate production for 2 minutes
./scripts/ttl-wrapper.sh -r 50 -t 120

# Burst mode testing for 30 seconds
./scripts/ttl-wrapper.sh -b -t 30
```

### Load Testing
```bash
# Generate 1000 messages in burst mode
./scripts/ttl-wrapper.sh -r 100 -t 10 -b

# Sustained load for 1 hour
./scripts/ttl-wrapper.sh -r 25 -t 3600
```

The producer will automatically stop after the TTL expires and display comprehensive statistics including:
- Total messages sent
- Actual production rate
- Elapsed time
- Remaining time (during operation)

## Architecture

The system uses:
- **Kafka**: Message streaming platform
- **Docker**: Containerized applications
- **Kubernetes**: Container orchestration
- **ConfigMaps**: Dynamic configuration management
- **Python**: Producer/consumer implementation with kafka-python library 