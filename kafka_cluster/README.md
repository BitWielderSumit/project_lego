# Project Lego

## Overview
**Project Lego** - A streamlined Kafka deployment project for local development using Bitnami Secure Images on Kubernetes (Docker Desktop).

- **Status**: Ready for deployment with single configuration file
- **Primary Focus**: KRaft mode Kafka deployment on Docker Desktop Kubernetes
- **Configuration Approach**: Single values file with clear, maintainable overrides

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
├── README.md                              # This comprehensive guide
└── kafka/                                 # Kafka deployment configuration
    ├── QUICKSTART.md                      # User guide
    ├── config/                            # Client configurations
    │   └── client.properties              # Kafka client settings
    ├── manifests/                         # Kubernetes manifests
    │   └── kafka-namespace.yaml           # Namespace definition
    ├── scripts/                           # Automation scripts
    │   ├── deploy-kafka.sh                # Main deployment
    │   ├── test-kafka.sh                  # Verification tests
    │   └── uninstall-kafka.sh             # Cleanup
    └── values/                            # Helm configuration
        └── values.yaml                    # Single configuration file (KRaft mode)
```

## Requirements
- **Docker Desktop** with Kubernetes enabled
- **Helm 3.8.0+** (tested with v3.17.0)
- **kubectl** configured for local cluster
- **Operating System**: macOS (darwin 24.5.0) - optimized for Docker Desktop

## Environment Setup
- **Kubernetes**: Docker Desktop cluster (freshly reset recommended)
- **Available Namespaces**: default, kube-node-lease, kube-public, kube-system
- **Target Namespace**: kafka (will be created during deployment)
- **Helm Chart**: Bitnami Kafka (oci://registry-1.docker.io/bitnamicharts/kafka)
- **Chart Version**: Latest (32.3.0 as of last check)

## Features
- ✅ **KRaft mode** - Modern Kafka without ZooKeeper dependency
- ✅ **Bitnami Secure Images** - Latest stable images (development tier)
- ✅ **Single configuration file** - Simple, maintainable values.yaml
- ✅ **Local development optimized** - Resource settings for Docker Desktop
- ✅ **Automated deployment** - One-command setup and teardown
- ✅ **Comprehensive testing** - Automated verification scripts
- ✅ **Well documented** - Clear guides and examples
- ✅ **Client configuration** - Pre-configured connection settings
- ✅ **Metrics enabled** - Kafka and JMX metrics for monitoring

## Technical Architecture

### Kafka Deployment Configuration
- **Mode**: KRaft (no ZooKeeper required)
- **Image**: Bitnami Secure Images with :latest tag (auto-updating for development)
- **Controller/Broker Replicas**: 1 each (local development)
- **Resource Preset**: "small" for both controller and broker
- **Storage**: 8Gi PVCs with default storage class
- **Authentication**: Plaintext (no security for local dev)
- **Metrics**: Kafka and JMX metrics enabled

### Technical Decisions Made
1. **KRaft Mode**: Modern Kafka architecture without ZooKeeper dependency
2. **Bitnami Secure Images**: Using free development tier with :latest tag
3. **Single Configuration**: One values.yaml file for simplicity and maintainability
4. **Local Development Focus**: Single replica, reduced resources for Docker Desktop
5. **Volume Permissions**: Enabled for Docker Desktop compatibility
6. **Authentication**: Plaintext for local development simplicity
7. **Automation**: Complete deployment, testing, and cleanup scripts

### Connection Details
- **Internal Service**: `kafka.kafka.svc.cluster.local:9092`
- **Protocol**: PLAINTEXT
- **Namespace**: kafka
- **Client Config**: kafka/config/client.properties

## Configuration Strategy
This project uses a **single configuration file** approach:
- One `values.yaml` file with clear, documented overrides
- KRaft mode enabled by default (modern Kafka architecture)
- Bitnami Secure Images :latest tag (auto-updating for development)
- Easy to understand and modify
- Optimized for local Docker Desktop environment

## Getting Started

### 1. Deploy Kafka
```bash
./kafka/scripts/deploy-kafka.sh
```
This script will:
- Create the kafka namespace
- Deploy Bitnami Kafka chart with local optimizations
- Set up client configuration

### 2. Test the Deployment
```bash
./kafka/scripts/test-kafka.sh
```
Automated verification including:
- Cluster connectivity
- Topic creation and deletion
- Producer and consumer functionality

### 3. Use Kafka
Connect to: `kafka-local.kafka.svc.cluster.local:9092`

Client configuration is pre-configured in `kafka/config/client.properties`

### 4. Clean Up
```bash
./kafka/scripts/uninstall-kafka.sh
```
Complete cleanup of all resources.

See [kafka/QUICKSTART.md](kafka/QUICKSTART.md) for detailed step-by-step instructions.

## Ready-to-Deploy Features
✅ **One-command deployment**: `./kafka/scripts/deploy-kafka.sh`  
✅ **Comprehensive testing**: `./kafka/scripts/test-kafka.sh`  
✅ **Complete cleanup**: `./kafka/scripts/uninstall-kafka.sh`  
✅ **Client configuration**: Pre-configured connection settings  
✅ **Documentation**: Detailed guides and troubleshooting  
✅ **Production template**: Ready for future production deployment  

## Next Possible Steps
- Deploy Kafka using the prepared configuration
- Add monitoring (Prometheus/Grafana) 
- Create application examples
- Add schema registry
- Implement security configurations

## Technical Notes

### For Developers
- **Single configuration file** - `kafka/values/values.yaml` contains all settings
- **KRaft mode** - Modern Kafka without ZooKeeper complexity
- **Bitnami Secure Images** - Using :latest tag (development tier, auto-updating)
- **Scripts are executable** - chmod +x already applied
- **Docker Desktop specific** - configurations optimized for local Docker Desktop environment

### Important: About :latest Tag
The configuration uses `bitnami/kafka:latest` which:
- ✅ Always gets the newest stable Kafka version
- ✅ No dependency on legacy repositories
- ⚠️ Version may change automatically (intended for development only)
- ⚠️ Not recommended for production use

### Troubleshooting
For detailed troubleshooting and configuration guidance, refer to:
- [kafka/QUICKSTART.md](kafka/QUICKSTART.md) - User guidance and step-by-step instructions

---

**Last Updated**: Complete Kafka configuration setup with all deployment files ready