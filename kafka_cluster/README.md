# Project Lego

## Overview
A comprehensive Kafka deployment project for local development using Bitnami Kafka charts on Kubernetes (Docker Desktop).

## Quick Start
```bash
# Deploy Kafka cluster
./kafka/scripts/deploy-kafka.sh

# Test the deployment
./kafka/scripts/test-kafka.sh

# Clean up when done
./kafka/scripts/uninstall-kafka.sh
```

## Project Structure
```
project_lego/
├── README.md                              # This file
├── AI_CONTEXT.md                          # Context for AI assistants
└── kafka/                                 # Kafka deployment configuration
    ├── QUICKSTART.md                      # Quick start guide
    ├── config/                            # Client configurations
    │   └── client.properties              # Kafka client settings
    ├── docs/                              # Documentation
    │   └── configuration-strategy.md      # Configuration approach
    ├── manifests/                         # Kubernetes manifests
    │   └── kafka-namespace.yaml           # Namespace definition
    ├── scripts/                           # Automation scripts
    │   ├── deploy-kafka.sh                # Deploy Kafka cluster
    │   ├── test-kafka.sh                  # Test cluster functionality
    │   └── uninstall-kafka.sh             # Clean up deployment
    └── values/                            # Helm values files
        ├── local-dev-values.yaml          # Local development config
        ├── minimal-kafka-values.yaml      # Minimal overrides
        ├── kafka-values.yaml              # Original config file
        └── production-values.yaml         # Production template
```

## Features
- ✅ **Override-only configuration** - Only specify values you want to change
- ✅ **Local development optimized** - Resource settings for Docker Desktop
- ✅ **Automated deployment** - One-command setup and teardown
- ✅ **Comprehensive testing** - Automated verification scripts
- ✅ **Production ready** - Template for production deployments
- ✅ **Well documented** - Clear guides and examples

## Requirements
- Docker Desktop with Kubernetes enabled
- Helm 3.8.0+
- kubectl configured for local cluster

## Getting Started
1. **Deploy**: `./kafka/scripts/deploy-kafka.sh`
2. **Test**: `./kafka/scripts/test-kafka.sh`
3. **Use**: Connect to `kafka.kafka.svc.cluster.local:9092`
4. **Clean**: `./kafka/scripts/uninstall-kafka.sh`

See [kafka/QUICKSTART.md](kafka/QUICKSTART.md) for detailed instructions.

## Configuration Strategy
This project uses an **override-only** approach:
- Only specify values we want to change from defaults
- Maintain ~60-100 lines instead of 2,400+ default lines
- Easy updates and maintenance
- Clear separation of customizations

See [kafka/docs/configuration-strategy.md](kafka/docs/configuration-strategy.md) for details.