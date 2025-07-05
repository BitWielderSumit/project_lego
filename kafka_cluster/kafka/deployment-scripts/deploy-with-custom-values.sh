#!/bin/bash

# Deploy Kafka with CUSTOM values for local development
echo "🚀 Deploying Kafka with custom local development settings..."

# Create namespace
kubectl apply -f ../manifests/kafka-namespace.yaml

# Install Kafka with custom values
helm upgrade --install kafka-local \
  oci://registry-1.docker.io/bitnamicharts/kafka \
  --namespace kafka \
  --values ../values/kafka-values.yaml \
  --wait

echo "✅ Kafka deployed with custom settings!"
echo "📊 Check resources with: kubectl get pods -n kafka" 