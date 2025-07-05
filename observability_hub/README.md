# 🔭 Observability Hub

## Overview
Your mission control center for comprehensive monitoring of Kafka clusters and Kubernetes infrastructure. Built with Prometheus Operator, Grafana, and AlertManager for complete observability.

## 🚀 Quick Launch
```bash
# Deploy the observability stack
./observability_hub/scripts/deploy-observatory.sh

# Run system diagnostics
./observability_hub/scripts/test-observatory.sh

# Access mission control (Grafana)
kubectl get svc -n observability grafana

# Shutdown observatory
./observability_hub/scripts/shutdown-observatory.sh
```

## 🎯 Mission Components

### Core Observatory Stack
- **🔍 Prometheus Operator**: Intelligent metrics orchestration
- **📊 Prometheus Server**: Time-series data collection and storage
- **📈 Grafana**: Visual mission control dashboards
- **🚨 AlertManager**: Smart alert routing and management

### Surveillance Targets
- **☕ Kafka Ecosystem**: JMX metrics, broker vitals, topic analytics
- **🚢 Kubernetes Fleet**: Node health, pod status, resource utilization
- **⚙️ System Telemetry**: CPU, memory, disk, network intelligence

## 🏗️ Observatory Architecture
```
project_lego/
├── kafka_cluster/                          # Your existing Kafka infrastructure
└── observability_hub/                      # Mission control center
    ├── README.md                           # Mission briefing (this file)
    ├── scripts/                            # Launch control scripts
    │   ├── deploy-observatory.sh           # Deploy full observatory
    │   ├── test-observatory.sh             # System diagnostics
    │   └── shutdown-observatory.sh         # Graceful shutdown
    ├── values/                             # Configuration profiles
    │   ├── prometheus-stack-values.yaml    # Core stack configuration
    │   └── kafka-telemetry-values.yaml     # Kafka monitoring integration
    ├── dashboards/                         # Visual control panels
    │   ├── kafka-command-center.json       # Kafka monitoring dashboard
    │   └── cluster-overview.json           # Kubernetes cluster dashboard
    └── alerts/                             # Alert command center
        ├── kafka-alerts.yaml               # Kafka alerting rules
        └── cluster-alerts.yaml             # Cluster alerting rules
```

## ✨ Observatory Features
- 🎛️ **Prometheus Operator** - Advanced metrics orchestration
- 🌍 **Full-spectrum monitoring** - Kafka + Kubernetes ecosystem
- 📊 **Pre-configured dashboards** - Ready-to-use visual analytics
- 🔗 **Auto-discovery** - Intelligent service monitoring
- 🌐 **External access** - LoadBalancer for easy mission control access
- 🚨 **Alert framework** - Extensible notification system

## 📋 Mission Prerequisites
- Active Kafka cluster with JMX telemetry enabled
- Docker Desktop with Kubernetes operational
- Helm 3.8.0+ for deployment orchestration
- kubectl configured for cluster access

## 🛸 Launch Sequence
1. **🚀 Deploy**: `./observability_hub/scripts/deploy-observatory.sh`
2. **🔍 Diagnose**: `./observability_hub/scripts/test-observatory.sh`
3. **🎯 Access**: Connect to Grafana via LoadBalancer URL
4. **📊 Monitor**: Import additional dashboards as needed
5. **🛑 Shutdown**: `./observability_hub/scripts/shutdown-observatory.sh`

## 🎮 Mission Control Access

### Grafana Command Center
- **Username**: `admin`
- **Password**: Retrieved during deployment
- **Access**: LoadBalancer URL (displayed post-deployment)

### Prometheus Data Center
- **Access**: `kubectl port-forward svc/prometheus-operated 9090:9090 -n observability`
- **URL**: `http://localhost:9090`

### AlertManager Control Room
- **Access**: `kubectl port-forward svc/alertmanager-operated 9093:9093 -n observability`
- **URL**: `http://localhost:9093`

## 🔌 Kafka Integration
Seamless integration with your existing Kafka infrastructure:
- **ServiceMonitor**: Auto-discovery of Kafka JMX endpoints
- **Custom dashboards**: Kafka-specific visual analytics
- **Alert rules**: Pre-configured Kafka health monitoring

## 🎯 Next Mission Objectives
1. **📊 Dashboard expansion**: Import community visualization packs
2. **🚨 Alert configuration**: Set up notification channels
3. **📈 Custom metrics**: Add application-specific telemetry
4. **🔧 Production tuning**: Optimize for scale and performance

## 🔧 Troubleshooting Command Center

### Pod Status Check
```bash
kubectl get pods -n observability
kubectl describe pods -n observability
```

### Mission Control Access Issues
```bash
kubectl get svc -n observability
kubectl port-forward svc/grafana 3000:3000 -n observability
```

### Telemetry Issues
```bash
kubectl logs -n observability prometheus-operated-0
kubectl get servicemonitor -n observability
```

### Emergency Diagnostics
```bash
# Full system status
kubectl get all -n observability

# Resource utilization
kubectl top pods -n observability

# Recent events
kubectl get events -n observability --sort-by='.lastTimestamp'
```

---
*🌟 Welcome to your Observability Hub - Where data meets insight!* 