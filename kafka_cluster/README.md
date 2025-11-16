# Project Lego

## Overview
**Project Lego** - A comprehensive Kafka deployment project for local development using Bitnami Kafka charts on Kubernetes (Docker Desktop).

- **Status**: Kafka configuration complete, ready for deployment
- **Primary Focus**: Bitnami Kafka deployment on Docker Desktop Kubernetes
- **Configuration Approach**: Override-only (maintain ~60-100 lines vs 2,400+ defaults)

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
    ├── docs/                              # Documentation
    │   └── configuration-strategy.md      # Architecture decisions
    ├── manifests/                         # Kubernetes manifests
    │   └── kafka-namespace.yaml           # Namespace definition
    ├── scripts/                           # Automation scripts
    │   ├── deploy-kafka.sh                # Main deployment
    │   ├── test-kafka.sh                  # Verification tests
    │   └── uninstall-kafka.sh             # Cleanup
    └── values/                            # Helm configurations
        ├── local-dev-values.yaml          # Primary config (optimized for local)
        ├── minimal-kafka-values.yaml      # Absolute minimal overrides
        ├── kafka-values.yaml              # Original comprehensive config
        └── production-values.yaml         # Production template
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
- ✅ **Override-only configuration** - Only specify values you want to change
- ✅ **Local development optimized** - Resource settings for Docker Desktop
- ✅ **Automated deployment** - One-command setup and teardown
- ✅ **Comprehensive testing** - Automated verification scripts
- ✅ **Production ready** - Template for production deployments
- ✅ **Well documented** - Clear guides and examples
- ✅ **Client configuration** - Pre-configured connection settings
- ✅ **Metrics enabled** - Kafka and JMX metrics for monitoring

## Technical Architecture

### Kafka Deployment Configuration
- **Local Optimizations**: Single replica, reduced resources, Docker Desktop compatibility
- **Controller/Broker Replicas**: 1 each
- **Resource Preset**: "small" for both controller and broker
- **Storage**: 8Gi PVCs with default storage class
- **Authentication**: Plaintext (no security for local dev)
- **Provisioning**: Enabled with test-topic creation

### Technical Decisions Made
1. **Override-Only Configuration**: Only specify changed values, not entire 2,400+ line config
2. **Local Development Focus**: Single replica, reduced resources for Docker Desktop
3. **Volume Permissions**: Enabled `volumePermissions.enabled=true` for Docker Desktop compatibility
4. **Authentication**: Plaintext for local development (production template uses SASL_SSL)
5. **Zookeeper**: Traditional Kafka + ZooKeeper (KRaft disabled for simplicity)
6. **Automation**: Complete deployment, testing, and cleanup scripts

### Connection Details
- **Internal Service**: `kafka.kafka.svc.cluster.local:9092`
- **Protocol**: PLAINTEXT
- **Namespace**: kafka
- **Client Config**: kafka/config/client.properties

## Configuration Strategy
This project uses an **override-only** approach:
- Only specify values we want to change from defaults
- Maintain ~60-100 lines instead of 2,400+ default lines
- Easy updates and maintenance
- Clear separation of customizations

See [kafka/docs/configuration-strategy.md](kafka/docs/configuration-strategy.md) for detailed configuration approach.

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
Connect to: `kafka.kafka.svc.cluster.local:9092`

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
- **All configuration files are ready** - no additional setup needed before deployment
- **Scripts are executable** - chmod +x already applied
- **Override-only approach** - maintain this pattern for any new configurations
- **Docker Desktop specific** - configurations optimized for local Docker Desktop environment

### Configuration Files
- **local-dev-values.yaml**: Primary configuration optimized for local development
- **minimal-kafka-values.yaml**: Absolute minimal overrides for reference
- **kafka-values.yaml**: Original comprehensive configuration
- **production-values.yaml**: Template for production deployments

### Troubleshooting
For detailed troubleshooting and configuration guidance, refer to:
- [kafka/QUICKSTART.md](kafka/QUICKSTART.md) - User guidance
- [kafka/docs/configuration-strategy.md](kafka/docs/configuration-strategy.md) - Technical details

---

**Last Updated**: Complete Kafka configuration setup with all deployment files ready