# Kafka Quick Start Guide

This guide helps you quickly deploy and test Kafka with KRaft mode using Bitnami Secure Images on your local Docker Desktop Kubernetes cluster.

## 🚀 Quick Deployment

### Prerequisites
- Docker Desktop with Kubernetes enabled
- Helm 3.8.0+ installed
- kubectl configured to use your local cluster

### 1. Deploy Kafka (One Command)
```bash
# From project root
./kafka/scripts/deploy-kafka.sh
```

This script will:
- ✅ Check prerequisites
- ✅ Create namespace
- ✅ Deploy Kafka in KRaft mode (no ZooKeeper)
- ✅ Apply consumer offsets fix for KRaft
- ✅ Show deployment status and connection info

### 2. Test Your Deployment
```bash
./kafka/scripts/test-kafka.sh
```

This will run comprehensive tests to verify everything is working.

## 📋 Manual Step-by-Step

If you prefer manual deployment:

### 1. Create Namespace
```bash
kubectl create namespace kafka
```

### 2. Deploy with Helm
```bash
helm upgrade --install kafka-local \
  oci://registry-1.docker.io/bitnamicharts/kafka \
  --namespace kafka \
  --values kafka/values/values.yaml \
  --wait
```

### 3. Verify Deployment
```bash
kubectl get pods -n kafka
kubectl get svc -n kafka
```

## 🧪 Testing Kafka

### Interactive Shell
```bash
kubectl run kafka-client --rm -i --tty \
  --image bitnami/kafka:latest \
  --namespace kafka -- bash
```

### Create a Topic
```bash
kafka-topics.sh --create --topic my-topic \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 \
  --partitions 1 --replication-factor 1
```

### Send Messages (Producer)
```bash
kafka-console-producer.sh --topic my-topic \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092
```

### Read Messages (Consumer)
```bash
kafka-console-consumer.sh --topic my-topic \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 \
  --from-beginning
```

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `kafka/values/values.yaml` | Single configuration file (KRaft mode, Bitnami Secure Images) |
| `kafka/config/client.properties` | Client connection settings |

### About the Configuration
- **KRaft Mode**: Modern Kafka without ZooKeeper dependency
- **Bitnami Secure Images**: Using `:latest` tag (free development tier)
- **Single File**: All settings in one place for simplicity
- **Auto-updating**: :latest tag means you always get the newest stable version

## 📊 Monitoring

### View Logs
```bash
kubectl logs -f deployment/kafka-local -n kafka
```

### Check Resource Usage
```bash
kubectl top pods -n kafka
```

### Port Forward for External Access
```bash
kubectl port-forward svc/kafka-local 9092:9092 -n kafka
```

## 🗑️ Cleanup

### Remove Everything
```bash
./kafka/scripts/uninstall-kafka.sh
```

## 🔗 Connection Information

**From inside Kubernetes:**
- Bootstrap Servers: `kafka-local.kafka.svc.cluster.local:9092`
- Protocol: `PLAINTEXT`
- Mode: KRaft (no ZooKeeper)

**From localhost (with port-forward):**
- Bootstrap Servers: `localhost:9092`
- Protocol: `PLAINTEXT`

## 📚 Next Steps

1. **Application Integration**: Use `kafka/config/client.properties` in your apps
2. **Topic Management**: Create topics using Kafka CLI or programmatically
3. **Monitoring**: Add Prometheus/Grafana for observability (metrics already enabled)
4. **Production**: Consider version pinning or Strimzi operator for production deployments

## 🆘 Troubleshooting

### Pods Not Starting
```bash
kubectl describe pods -n kafka
kubectl logs -n kafka -l app.kubernetes.io/name=kafka
```

### Connection Issues
```bash
kubectl get svc -n kafka
kubectl port-forward svc/kafka-local 9092:9092 -n kafka
```

### Storage Issues
```bash
kubectl get pvc -n kafka
kubectl describe pvc -n kafka
```

### Clean Restart
```bash
./kafka/scripts/uninstall-kafka.sh
./kafka/scripts/deploy-kafka.sh
``` 