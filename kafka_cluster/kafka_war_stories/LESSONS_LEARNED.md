# 🎓 Kafka Deployment Lessons Learned
## Wisdom Earned Through Battle

---

## 🏗️ Configuration Architecture Lessons

### 1. **KRaft Mode Design Principles**
```yaml
# ✅ GOOD: Combined controller+broker for single-node dev
kraft:
  enabled: true
controller:
  controllerOnly: false  # Controller acts as broker
  replicaCount: 1
broker:
  replicaCount: 0       # No separate brokers

# ❌ BAD: Dedicated architecture for single-node
controller:
  controllerOnly: true  # Wasteful resource allocation
broker:
  replicaCount: 1      # Unnecessary complexity
```

**Rule**: For local development, use combined mode. For production, use dedicated controllers.

### 2. **YAML Structure Discipline**
```yaml
# ❌ DANGER: Duplicate sections
controller:
  replicaCount: 1
# ... other stuff ...
controller:          # ← DUPLICATE! Chart processes both
  controllerOnly: false

# ✅ SAFE: Single consolidated section
controller:
  replicaCount: 1
  controllerOnly: false
```

**Rule**: Always use `helm template` to preview before deployment. Validate YAML structure.

---

## 🌐 Service Discovery Lessons

### 3. **Helm Release Name Propagation**
```bash
# Release name: "kafka-local"
# Service becomes: "kafka-local.kafka.svc.cluster.local"

# ✅ CORRECT bootstrap server pattern
--bootstrap-server {{ .Release.Name }}.kafka.svc.cluster.local:9092

# ❌ COMMON MISTAKE: hardcoded generic names
--bootstrap-server kafka.kafka.svc.cluster.local:9092
```

**Rule**: Service names follow pattern `{RELEASE_NAME}.{NAMESPACE}.svc.cluster.local`

### 4. **Configuration Consistency Across Files**
Update these files together when changing service names:
- `kafka/scripts/*.sh` (all test scripts)
- `kafka/config/client.properties`
- Documentation examples
- Helm values files

**FIXED**: All scripts now use `${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local` pattern.

**Rule**: Service name changes require multi-file coordination.

---

## 💾 Message Persistence Lessons

### 5. **Single-Replica Commitment Requirements**
```yaml
# ✅ ESSENTIAL for single-replica dev environments
config: |
  min.insync.replicas=1              # Require 1 replica (self) acknowledgment
  log.flush.interval.messages=1      # Flush after each message
  log.flush.interval.ms=1000        # Regular time-based flush
  default.replication.factor=1       # Single replica default
```

**Critical Discovery**: Default Kafka settings optimize for multi-replica clusters. Single-replica needs explicit commitment configuration.

### 6. **High Watermark vs Log End Offset**
- **High Watermark**: Last committed offset (consumer visible)
- **Log End Offset**: Last written offset (may exceed watermark)
- **Gap**: Uncommitted messages (producer wrote, but not yet consumer-visible)

**Rule**: Always check both offsets when debugging consumer issues:
```bash
kafka-get-offsets.sh --topic test  # Shows log end offset
# vs consumer behavior (high watermark dependent)
```

### 7. **Producer Acknowledgment Impact**
```bash
# ❌ Default: May not commit messages immediately
kafka-console-producer.sh --topic test

# ✅ Explicit: Forces commitment
kafka-console-producer.sh --topic test --producer-property acks=1
```

**Rule**: In development, always use `acks=1` or configure broker-level flush settings.

---

## 🔧 Operational Lessons

### 8. **Diagnostic Command Priority**
When troubleshooting, run commands in this order:
1. `kubectl get pods -n kafka` (basic health)
2. `kubectl get svc -n kafka` (service discovery)
3. `kafka-topics.sh --list` (basic connectivity)
4. `kafka-get-offsets.sh --topic X` (message storage verification)
5. `kafka-topics.sh --describe --topic X` (ISR status)
6. `kubectl logs` (detailed investigation)

**Rule**: Start broad (cluster health) → narrow to specific (message-level debugging)

### 9. **Container Selection for Commands**
```bash
# ✅ GOOD: Use client pod (no JMX conflicts)
kubectl exec -n kafka kafka-local-client -- kafka-topics.sh ...

# ⚠️ RISKY: Direct controller exec (JMX port conflicts possible)
kubectl exec -n kafka kafka-local-controller-0 -- kafka-topics.sh ...
```

**Rule**: Client pods are safer for administrative commands.

### 10. **Resource Planning for Docker Desktop**
- **Single Controller+Broker**: ~1GB RAM, 0.5 CPU
- **Separate Controller+Broker**: ~2GB RAM, 1 CPU
- **With Monitoring (JMX)**: +500MB RAM

**Rule**: Combined mode more efficient for local development constraints.

---

## 📋 Deployment Process Lessons

### 11. **Incremental Deployment Strategy**
1. **Start Minimal**: Deploy simplest working configuration
2. **Verify Core**: Test basic producer/consumer flow
3. **Add Features**: Security, monitoring, persistence
4. **Performance Tune**: Only after basic functionality verified

**Rule**: Don't try to solve everything in first deployment.

### 12. **Configuration Testing Approach**
```bash
# Test sequence for each configuration change:
helm template -f values.yaml . > test-manifest.yaml  # Preview
helm upgrade --dry-run kafka-local . -f values.yaml  # Validation
helm upgrade kafka-local . -f values.yaml            # Deploy
# Test end-to-end functionality
# Monitor logs for 5 minutes
```

**Rule**: Preview → Validate → Deploy → Test → Monitor

---

## 🚨 Red Flag Warning Signs

### 13. **Configuration Red Flags**
- Duplicate YAML sections
- Service names hardcoded as "kafka.kafka"
- `kraft.enabled=false` with KRaft cluster
- `log.flush.interval.ms` not set for single-replica
- Missing `min.insync.replicas` setting

### 14. **Operational Red Flags**
- "High watermark 0" with messages stored
- Consumer groups not forming
- DNS resolution failures
- Multiple controller pods unexpectedly
- Pod resource requests exceeding node capacity

**Rule**: These patterns indicate fundamental configuration issues requiring immediate attention.

---

## 🎯 Success Criteria Definition

### 15. **Deployment Success Verification**
A Kafka deployment is successful when:
```bash
✅ kubectl get pods -n kafka → All Running
✅ Topic creation succeeds
✅ Message production succeeds  
✅ kafka-get-offsets.sh shows messages stored
✅ Consumer reads messages immediately
✅ Consumer groups coordinate properly
✅ Service discovery works from all pods
```

**Rule**: All 7 criteria must pass for operational readiness.

---

## 🔮 Future Deployment Wisdom

### 16. **Avoid These Battles Next Time**
1. **Start with known-good values file** (save the final working configuration)
2. **Use consistent naming conventions** (service names, release names)
3. **Test with minimal configuration first** (add complexity incrementally)
4. **Document service dependencies** (what talks to what)
5. **Automate health checks** (don't rely on manual verification)

### 17. **Configuration Templates**
Create reusable templates for:
- Local development (single-replica, aggressive flush)
- Production (multi-replica, balanced performance)
- Testing (ephemeral, fast startup)

**Rule**: Template-driven deployment reduces configuration errors.

---

## 🔄 Chart Version Migration Lessons

### 18. **Bitnami Chart Architecture Changes (v32.0.0+)**
**Major Breaking Change**: Dual StatefulSet architecture introduced
- **Before**: Single StatefulSet with combined controller+broker
- **After**: Separate controller and broker StatefulSets

**Consumer Offsets Topic Issue**:
```bash
# ❌ SYMPTOM: Auto-creation fails in new architecture
kafka-console-consumer.sh --topic test --from-beginning  # 0 messages
kafka-topics.sh --describe --topic __consumer_offsets     # Topic does not exist

# ✅ SOLUTION: Automated topic creation in deployment script
create_consumer_offsets_topic() {
    kubectl run kafka-topic-create --rm -i --image bitnami/kafka:latest \
        --namespace ${NAMESPACE} --restart=Never -- \
        kafka-topics.sh --create --topic __consumer_offsets \
        --bootstrap-server ${RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9092 \
        --partitions 50 --replication-factor 1 \
        --config cleanup.policy=compact --if-not-exists
}
```

**Automated Prevention**: Enhanced deployment script with:
- **Chart Version Detection**: Only applies fix to KRaft deployments
- **Existence Check**: Prevents duplicate topic creation
- **Proper Configuration**: 50 partitions, compact cleanup policy
- **Safety Features**: Uses `--if-not-exists` flag

**Rule**: Major chart version upgrades require testing of full producer/consumer workflows, not just cluster health.

**Reference**: Related to [GitHub Issue #32851](https://github.com/bitnami/charts/issues/32851)

---

## 💎 Golden Rules Summary

1. **Architecture**: Dual StatefulSet (controller + broker) for v32.0.0+
2. **Service Names**: Follow Helm release naming patterns
3. **Message Commitment**: Explicit settings for single-replica
4. **YAML Validation**: Preview before deploy
5. **Diagnostic Order**: Broad to narrow investigation
6. **Success Criteria**: Full end-to-end verification required
7. **Chart Upgrades**: Test producer/consumer workflows after major versions
8. **Automation**: Build deployment fixes into scripts for known issues

*"Configuration is code. Test it like code."* 

---

**Next Deployment Time**: 30 minutes (instead of 18 hours) 🚀 