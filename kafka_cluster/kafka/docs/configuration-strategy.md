# Kafka Configuration Strategy

## Override-Only Approach ✅

This project uses **override-only** configuration files, following Helm best practices.

### What this means:
- We only specify values we want to **change** from defaults
- Helm automatically merges our overrides with chart defaults
- We maintain ~60 lines instead of 2,400+ lines
- Updates are easy and safe

### Benefits:
1. **Maintainability**: Only track what matters to us
2. **Upgrades**: Chart updates bring new features automatically  
3. **Security**: Get security patches without manual work
4. **Clarity**: Clear what we've customized vs. defaults

### File Structure:
```
kafka/values/
├── kafka-values.yaml          # Full local dev config (~64 lines)
├── minimal-kafka-values.yaml  # Absolute minimum (~25 lines)
└── production-values.yaml     # Future: production overrides
```

### Deployment:
```bash
# Uses our overrides + chart defaults
helm install kafka oci://registry-1.docker.io/bitnamicharts/kafka \
  --values kafka/values/kafka-values.yaml
```

### NOT Recommended ❌:
- Downloading/copying the entire chart locally
- Maintaining full 2,400+ line configuration files
- Forking the Bitnami chart repository 