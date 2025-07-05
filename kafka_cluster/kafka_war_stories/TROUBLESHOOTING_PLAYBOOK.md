# 🚨 Kafka Emergency Playbook
## Quick Fix Guide for Common Battle Wounds

---

## 🔥 Emergency Diagnostics (First 5 Minutes)

```bash
# 1. Check cluster health
kubectl get pods -n kafka

# 2. Check service endpoints
kubectl get svc -n kafka

# 3. Check recent logs (last 50 lines)
kubectl logs kafka-local-controller-0 -n kafka --tail=50

# 4. Test basic connectivity
kubectl exec -n kafka kafka-local-client -- kafka-topics.sh --list \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092
```

---

## ⚡ Common Issues & Lightning Fixes

### 🚨 Issue: "DNS resolution failed for kafka.kafka.svc.cluster.local"
**Quick Fix**: Service name is wrong!
```bash
# ❌ Wrong
--bootstrap-server kafka.kafka.svc.cluster.local:9092

# ✅ Correct  
--bootstrap-server kafka-local.kafka.svc.cluster.local:9092
```

### 🚨 Issue: "Messages produced but consumer gets 0 messages"
**Quick Fix**: High watermark issue - messages not committed!
```bash
# Test with explicit acknowledgment
echo "test" | kubectl exec -n kafka kafka-local-client -- \
  kafka-console-producer.sh --topic debug-test \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 \
  --producer-property acks=1

# Verify message is consumable
kubectl exec -n kafka kafka-local-client -- \
  kafka-console-consumer.sh --topic debug-test \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 \
  --from-beginning --timeout-ms 5000
```

### 🚨 Issue: Consumer group coordination failures
**Quick Fix**: Check `__consumer_offsets` topic
```bash
# Verify consumer offsets topic exists
kubectl exec -n kafka kafka-local-client -- kafka-topics.sh --list \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 | grep consumer_offsets

# If missing, check KRaft mode configuration
kubectl get configmap kafka-local-controller-configuration -n kafka -o yaml
```

### 🚨 Issue: Multiple controller pods when expecting 1
**Quick Fix**: YAML structure problem
```bash
# Check for duplicate sections in values file
grep -n "controller:" kafka/values/local-dev-values-kraft.yaml
# Should only appear ONCE
```

### 🚨 Issue: Pods stuck in Pending state
**Quick Fix**: Resource constraints on Docker Desktop
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Check pod resource requests
kubectl describe pod kafka-local-controller-0 -n kafka | grep -A5 "Requests:"
```

---

## 🧪 Diagnostic Commands Arsenal

### Message Flow Testing
```bash
# End-to-end test (30 second version)
TOPIC="quicktest-$(date +%s)"

# Create & send message
kubectl exec -n kafka kafka-local-client -- kafka-topics.sh \
  --create --topic $TOPIC --partitions 1 --replication-factor 1 \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092

echo "Test message $(date)" | kubectl exec -n kafka kafka-local-client -- \
  kafka-console-producer.sh --topic $TOPIC \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 \
  --producer-property acks=1

# Verify storage & consumption
kubectl exec -n kafka kafka-local-client -- kafka-get-offsets.sh \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 --topic $TOPIC

kubectl exec -n kafka kafka-local-client -- \
  kafka-console-consumer.sh --topic $TOPIC \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 \
  --from-beginning --timeout-ms 5000
```

### Configuration Audit
```bash
# Check actual broker configuration
kubectl exec -n kafka kafka-local-controller-0 -- cat /opt/bitnami/kafka/config/server.properties | grep -E "(kraft|min.insync|flush|replication)"

# Check Helm values applied
helm get values kafka-local -n kafka
```

### Performance Check
```bash
# Resource usage
kubectl top pods -n kafka

# Disk usage in pods
kubectl exec -n kafka kafka-local-controller-0 -- df -h /bitnami/kafka/data
```

---

## 🩹 Configuration Hot Fixes

### Force Message Commitment (Single Replica)
```yaml
# Add to values file under config: |
min.insync.replicas=1
log.flush.interval.messages=1
log.flush.interval.ms=1000
default.replication.factor=1
```

### KRaft Mode Activation
```yaml
kraft:
  enabled: true
controller:
  controllerOnly: false
  replicaCount: 1
broker:
  replicaCount: 0
```

### Service Name Quick Fix
```bash
# Find actual service name
kubectl get svc -n kafka | grep kafka-local

# Update scripts (replace kafka.kafka with kafka-local)
sed -i 's/kafka\.kafka/kafka-local/g' kafka/scripts/*.sh
sed -i 's/kafka\.kafka/kafka-local/g' kafka/config/client.properties
```

---

## 🔄 Emergency Restart Procedures

### Soft Restart (Preserve Data)
```bash
kubectl rollout restart statefulset/kafka-local-controller -n kafka
kubectl rollout restart statefulset/kafka-local-broker -n kafka  # if exists
```

### Nuclear Option (Clean Redeploy)
```bash
./kafka/scripts/uninstall-kafka.sh
./kafka/scripts/deploy-kafka.sh kraft
```

### Data Preservation Restart
```bash
# Scale down
kubectl scale statefulset kafka-local-controller --replicas=0 -n kafka

# Wait for graceful shutdown
kubectl get pods -n kafka -w

# Scale back up
kubectl scale statefulset kafka-local-controller --replicas=1 -n kafka
```

---

## 📞 Emergency Contacts (Documentation)
- **Main Battle Log**: `kafka_war_stories/DEPLOYMENT_BATTLES.md`
- **Configuration Guide**: `kafka/docs/configuration-strategy.md`  
- **Quick Start**: `kafka/QUICKSTART.md`
- **Scripts**: `kafka/scripts/`

---

## 🏥 Health Check Automation
```bash
# Add to crontab or monitoring system
#!/bin/bash
echo "=== Kafka Health Check $(date) ==="
kubectl get pods -n kafka
kubectl exec -n kafka kafka-local-client -- kafka-topics.sh --list \
  --bootstrap-server kafka-local.kafka.svc.cluster.local:9092 2>/dev/null \
  && echo "✅ Kafka responsive" || echo "❌ Kafka not responding"
```

*Keep calm and carry on.* ☕ 