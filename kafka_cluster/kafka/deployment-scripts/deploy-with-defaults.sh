#!/bin/bash

# Deploy Kafka with DEFAULT settings (no custom values)
echo "🚀 Deploying Kafka with default Bitnami settings..."

# Create namespace
kubectl create namespace kafka-default --dry-run=client -o yaml | kubectl apply -f -

# Install Kafka with defaults
helm upgrade --install kafka-default \
  oci://registry-1.docker.io/bitnamicharts/kafka \
  --namespace kafka-default \
  --wait

echo "✅ Kafka deployed with defaults!"
echo "📊 Check resources with: kubectl get pods -n kafka-default" 