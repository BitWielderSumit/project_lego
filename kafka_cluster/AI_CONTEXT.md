# AI Context File

## Project Overview
**Project Lego** - A comprehensive Kafka deployment project for local development using Bitnami Kafka charts on Kubernetes.

## Current Project State
- **Project**: Project Lego
- **Status**: Kafka configuration complete, ready for deployment
- **Location**: /Users/sumitagrawal/procore/workspaces/notes/project_lego
- **Primary Focus**: Bitnami Kafka deployment on Docker Desktop Kubernetes

## Environment Setup
- **Operating System**: macOS (darwin 24.5.0)
- **Kubernetes**: Docker Desktop cluster (freshly reset)
- **Available Namespaces**: default, kube-node-lease, kube-public, kube-system
- **Helm Version**: v3.17.0 (✅ meets requirements)
- **Target Namespace**: kafka (will be created during deployment)

## Project Architecture
### Kafka Deployment
- **Chart**: Bitnami Kafka (oci://registry-1.docker.io/bitnamicharts/kafka)
- **Version**: Latest (32.3.0 as of last check)
- **Configuration Approach**: Override-only (maintain ~60-100 lines vs 2,400+ defaults)
- **Local Optimizations**: Single replica, reduced resources, Docker Desktop compatibility

### Directory Structure
```
kafka/
├── QUICKSTART.md                 # User guide
├── config/client.properties      # Client connection settings
├── docs/configuration-strategy.md # Architecture decisions
├── manifests/kafka-namespace.yaml # K8s namespace
├── scripts/                      # Automation scripts
│   ├── deploy-kafka.sh          # Main deployment
│   ├── test-kafka.sh            # Verification tests
│   └── uninstall-kafka.sh       # Cleanup
└── values/                       # Helm configurations
    ├── local-dev-values.yaml    # Primary config (optimized for local)
    ├── minimal-kafka-values.yaml # Absolute minimal overrides
    ├── kafka-values.yaml        # Original comprehensive config
    └── production-values.yaml   # Production template
```

## Technical Decisions Made
1. **Override-Only Configuration**: Only specify changed values, not entire 2,400+ line config
2. **Local Development Focus**: Single replica, reduced resources for Docker Desktop
3. **Volume Permissions**: Enabled `volumePermissions.enabled=true` for Docker Desktop compatibility
4. **Authentication**: Plaintext for local development (production template uses SASL_SSL)
5. **Zookeeper**: Traditional Kafka + ZooKeeper (KRaft disabled for simplicity)
6. **Automation**: Complete deployment, testing, and cleanup scripts

## Deployment Configuration
### Local Development Settings
- **Controller/Broker Replicas**: 1 each
- **Resource Preset**: "small" for both controller and broker
- **Storage**: 8Gi PVCs with default storage class
- **Authentication**: Plaintext (no security for local dev)
- **Provisioning**: Enabled with test-topic creation
- **Metrics**: Kafka and JMX metrics enabled

### Connection Details
- **Internal Service**: kafka.kafka.svc.cluster.local:9092
- **Protocol**: PLAINTEXT
- **Namespace**: kafka
- **Client Config**: kafka/config/client.properties

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

## Notes for AI Assistants
- **All configuration files are ready** - no additional setup needed before deployment
- **Scripts are executable** - chmod +x already applied
- **Override-only approach** - maintain this pattern for any new configurations
- **Docker Desktop specific** - configurations optimized for local Docker Desktop environment
- **Well documented** - refer to kafka/QUICKSTART.md and kafka/docs/ for user guidance

## Last Updated
Complete Kafka configuration setup with all deployment files ready

