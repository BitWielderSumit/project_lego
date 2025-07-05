#!/bin/bash

# Observatory Deployment Script
# Deploys comprehensive monitoring stack with Prometheus Operator, Grafana, and AlertManager

set -e  # Exit on any error

# Help function
show_help() {
    echo "🔭 Observatory Deployment Script"
    echo "Deploy comprehensive monitoring for Kafka and Kubernetes infrastructure"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  basic       - Deploy basic monitoring stack only"
    echo "  grafana     - Deploy complete observatory with Grafana dashboards"
    echo "  full        - Deploy full observatory with Kafka integration (default)"
    echo "  upgrade     - Upgrade existing observatory deployment"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Deploy full observatory"
    echo "  $0 basic        # Deploy basic monitoring"
    echo "  $0 grafana      # Deploy with Grafana but no Kafka integration"
    echo "  $0 upgrade      # Upgrade existing deployment"
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="observability"
RELEASE_NAME="prometheus-stack"
CHART_REPO="bitnami/kube-prometheus"
VALUES_FILE="observability_hub/values/prometheus-stack-values.yaml"
KAFKA_VALUES_FILE="observability_hub/values/kafka-telemetry-values.yaml"

# Handle command line arguments
DEPLOYMENT_MODE="full"
if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
elif [ "$1" = "basic" ]; then
    DEPLOYMENT_MODE="basic"
    echo -e "${YELLOW}🔧 Deploying basic monitoring stack${NC}"
elif [ "$1" = "grafana" ]; then
    DEPLOYMENT_MODE="grafana"
    echo -e "${YELLOW}🔧 Deploying complete observatory with Grafana dashboards${NC}"
elif [ "$1" = "full" ]; then
    DEPLOYMENT_MODE="full"
    echo -e "${YELLOW}🔧 Deploying full observatory with Kafka integration${NC}"
elif [ "$1" = "upgrade" ]; then
    DEPLOYMENT_MODE="upgrade"
    echo -e "${YELLOW}🔧 Upgrading existing observatory deployment${NC}"
elif [ -n "$1" ]; then
    echo -e "${RED}❌ Unknown option: $1${NC}"
    echo -e "${YELLOW}Use '$0 help' for usage information${NC}"
    exit 1
fi

echo -e "${CYAN}🚀 Starting Observatory Deployment${NC}"
echo -e "${CYAN}📋 Mission Configuration:${NC}"
echo "  Release Name: ${RELEASE_NAME}"
echo "  Namespace: ${NAMESPACE}"
echo "  Deployment Mode: ${DEPLOYMENT_MODE}"
echo "  Values File: ${VALUES_FILE}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking mission prerequisites...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm is not installed or not in PATH${NC}"
    exit 1
fi

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

# Check if values file exists
if [ ! -f "${VALUES_FILE}" ]; then
    echo -e "${RED}❌ Values file not found: ${VALUES_FILE}${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Create namespace
echo -e "${YELLOW}📁 Creating observatory namespace: ${NAMESPACE}${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy Prometheus Stack
echo -e "${YELLOW}🎯 Deploying Prometheus Stack...${NC}"
helm upgrade --install ${RELEASE_NAME} \
    ${CHART_REPO} \
    --namespace ${NAMESPACE} \
    --values ${VALUES_FILE} \
    --wait \
    --timeout 15m

echo -e "${GREEN}✅ Prometheus Stack deployment completed!${NC}"

# Apply Kafka monitoring integration if full deployment
if [ "${DEPLOYMENT_MODE}" = "full" ]; then
    echo -e "${YELLOW}🔌 Applying Kafka monitoring integration...${NC}"
    
    # Check if Kafka cluster exists
    if kubectl get namespace kafka &> /dev/null; then
        echo -e "${YELLOW}  📋 Kafka cluster found, enhancing with monitoring...${NC}"
        
        # Apply enhanced Kafka monitoring configuration
        echo -e "${YELLOW}  🔧 Upgrading Kafka deployment with monitoring integration...${NC}"
        
        # Merge Kafka telemetry values with existing Kafka deployment
        if [ -f "kafka_cluster/kafka/values/local-dev-values-kraft.yaml" ]; then
            echo -e "${YELLOW}  📝 Merging telemetry configuration with existing Kafka values...${NC}"
            
            # Create a temporary merged values file
            TEMP_KAFKA_VALUES="/tmp/kafka-with-monitoring.yaml"
            cat kafka_cluster/kafka/values/local-dev-values-kraft.yaml > ${TEMP_KAFKA_VALUES}
            echo "" >> ${TEMP_KAFKA_VALUES}
            echo "# === MONITORING INTEGRATION ===" >> ${TEMP_KAFKA_VALUES}
            cat ${KAFKA_VALUES_FILE} >> ${TEMP_KAFKA_VALUES}
            
            # Upgrade Kafka with monitoring
            helm upgrade kafka-local \
                bitnami/kafka \
                --namespace kafka \
                --values ${TEMP_KAFKA_VALUES} \
                --wait \
                --timeout 10m
            
            # Clean up temporary file
            rm -f ${TEMP_KAFKA_VALUES}
            
            echo -e "${GREEN}  ✅ Kafka monitoring integration completed!${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Kafka values file not found. Skipping integration.${NC}"
            echo -e "${YELLOW}  💡 You can manually apply monitoring later using the telemetry values file.${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  Kafka cluster not found. Skipping Kafka integration.${NC}"
        echo -e "${YELLOW}  💡 Deploy Kafka first, then run this script again for full integration.${NC}"
    fi
fi

# Deploy Grafana if in grafana or full mode
if [ "${DEPLOYMENT_MODE}" = "grafana" ] || [ "${DEPLOYMENT_MODE}" = "full" ]; then
    echo -e "${YELLOW}📊 Deploying Grafana Dashboard...${NC}"
    
    # Check if Grafana is already deployed
    if helm list -n ${NAMESPACE} | grep -q "grafana"; then
        echo -e "${YELLOW}  🔄 Grafana already deployed, upgrading...${NC}"
        GRAFANA_ACTION="upgrade"
    else
        echo -e "${YELLOW}  🆕 Deploying new Grafana instance...${NC}"
        GRAFANA_ACTION="install"
    fi
    
    # Create Grafana datasources configuration
    echo -e "${YELLOW}  📝 Configuring Grafana datasources...${NC}"
    
    # Deploy Grafana with proper configuration including sidecar dashboard provisioning
    helm ${GRAFANA_ACTION} grafana \
        bitnami/grafana \
        --namespace ${NAMESPACE} \
        --set admin.user=admin \
        --set admin.password=observatory-admin \
        --set service.type=LoadBalancer \
        --set persistence.enabled=true \
        --set persistence.size=1Gi \
        --set datasources.secretDefinition.apiVersion=1 \
        --set datasources.secretDefinition.datasources[0].name=Prometheus \
        --set datasources.secretDefinition.datasources[0].type=prometheus \
        --set datasources.secretDefinition.datasources[0].access=proxy \
        --set datasources.secretDefinition.datasources[0].orgId=1 \
        --set datasources.secretDefinition.datasources[0].url=http://prometheus-stack-kube-prom-prometheus.observability.svc.cluster.local:9090 \
        --set datasources.secretDefinition.datasources[0].version=1 \
        --set datasources.secretDefinition.datasources[0].editable=true \
        --set datasources.secretDefinition.datasources[0].isDefault=true \
        --set datasources.secretDefinition.datasources[1].name=Alertmanager \
        --set datasources.secretDefinition.datasources[1].uid=alertmanager \
        --set datasources.secretDefinition.datasources[1].type=alertmanager \
        --set datasources.secretDefinition.datasources[1].access=proxy \
        --set datasources.secretDefinition.datasources[1].orgId=1 \
        --set datasources.secretDefinition.datasources[1].url=http://prometheus-stack-kube-prom-alertmanager.observability.svc.cluster.local:9093 \
        --set datasources.secretDefinition.datasources[1].version=1 \
        --set datasources.secretDefinition.datasources[1].editable=true \
        --wait \
        --timeout 10m
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✅ Grafana deployment completed!${NC}"
    else
        echo -e "${RED}  ❌ Grafana deployment failed!${NC}"
        exit 1
    fi
fi

# Apply alert rules if they exist
if [ -d "observability_hub/alerts" ] && [ "$(ls -A observability_hub/alerts)" ]; then
    echo -e "${YELLOW}🚨 Applying alert rules...${NC}"
    
    # Apply PrometheusRule objects
    for alert_file in observability_hub/alerts/*.yaml; do
        if [ -f "$alert_file" ]; then
            echo -e "${YELLOW}  📋 Applying $(basename "$alert_file")...${NC}"
            kubectl apply -f "$alert_file" -n ${NAMESPACE}
        fi
    done
    
    echo -e "${GREEN}  ✅ Alert rules applied!${NC}"
fi

# Post-deployment configuration
echo -e "${YELLOW}🔧 Applying post-deployment configuration...${NC}"

# Wait for all pods to be ready
echo -e "${YELLOW}  ⏳ Waiting for observatory components to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kube-prometheus-prometheus --timeout=300s -n ${NAMESPACE} || true
if [ "${DEPLOYMENT_MODE}" = "grafana" ] || [ "${DEPLOYMENT_MODE}" = "full" ]; then
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=300s -n ${NAMESPACE} || true
fi
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kube-prometheus-alertmanager --timeout=300s -n ${NAMESPACE} || true

echo -e "${GREEN}  ✅ Observatory components are ready!${NC}"

# Get service information
echo -e "${BLUE}📊 Observatory Status:${NC}"
kubectl get pods -n ${NAMESPACE}
echo ""
kubectl get svc -n ${NAMESPACE}
echo ""
kubectl get pvc -n ${NAMESPACE}
echo ""

# Display access information
echo -e "${BLUE}🎮 Mission Control Access Information:${NC}"
echo ""

# Grafana access
GRAFANA_SERVICE=$(kubectl get svc -n ${NAMESPACE} -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "${GRAFANA_SERVICE}" ]; then
    GRAFANA_TYPE=$(kubectl get svc -n ${NAMESPACE} ${GRAFANA_SERVICE} -o jsonpath='{.spec.type}')
    
    if [ "${GRAFANA_TYPE}" = "LoadBalancer" ]; then
        echo -e "${GREEN}📈 Grafana Dashboard (LoadBalancer):${NC}"
        kubectl get svc -n ${NAMESPACE} ${GRAFANA_SERVICE} -o wide
        echo ""
        echo -e "${YELLOW}  💡 It may take a few minutes for the LoadBalancer to assign an external IP${NC}"
        echo -e "${YELLOW}  💡 Use 'kubectl get svc -n ${NAMESPACE} ${GRAFANA_SERVICE} -w' to watch for external IP${NC}"
    else
        echo -e "${GREEN}📈 Grafana Dashboard (Port Forward):${NC}"
        echo "  kubectl port-forward svc/${GRAFANA_SERVICE} 3000:3000 -n ${NAMESPACE}"
        echo "  URL: http://localhost:3000"
    fi
else
    if [ "${DEPLOYMENT_MODE}" = "basic" ]; then
        echo -e "${YELLOW}📈 Grafana Dashboard:${NC}"
        echo "  Not deployed in basic mode. Use 'grafana' or 'full' mode for complete dashboard experience."
    else
        echo -e "${YELLOW}📈 Grafana Dashboard:${NC}"
        echo "  Service not found. Please check deployment status."
    fi
fi

echo ""
echo -e "${GREEN}🔍 Prometheus Server:${NC}"
echo "  kubectl port-forward svc/prometheus-operated 9090:9090 -n ${NAMESPACE}"
echo "  URL: http://localhost:9090"

echo ""
echo -e "${GREEN}🚨 AlertManager:${NC}"
echo "  kubectl port-forward svc/alertmanager-operated 9093:9093 -n ${NAMESPACE}"
echo "  URL: http://localhost:9093"

echo ""
echo -e "${GREEN}🔑 Grafana Credentials:${NC}"
echo "  Username: admin"
echo "  Password: observatory-admin"

echo ""
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "1. Access Grafana dashboard using the information above"
echo "2. Import additional dashboards from Grafana community"
echo "3. Configure alert notification channels in AlertManager"
echo "4. Test the monitoring setup:"
echo "   ./observability_hub/scripts/test-observatory.sh"
echo ""
echo "5. View logs:"
echo "   kubectl logs -f deployment/prometheus-stack-grafana -n ${NAMESPACE}"
echo "   kubectl logs -f prometheus-prometheus-stack-prometheus-0 -n ${NAMESPACE}"
echo ""

if [ "${DEPLOYMENT_MODE}" = "full" ]; then
    echo -e "${GREEN}🔌 Kafka Integration:${NC}"
    echo "  - ServiceMonitor: Automatically discovers Kafka metrics"
    echo "  - PrometheusRule: Kafka-specific alerts configured"
    echo "  - Dashboards: Ready for Kafka visualization"
    echo ""
elif [ "${DEPLOYMENT_MODE}" = "grafana" ]; then
    echo -e "${GREEN}🎨 Grafana Observatory:${NC}"
    echo "  - Complete monitoring stack with visual dashboards"
    echo "  - Ready for custom dashboard imports"
    echo "  - Kafka integration can be added later with 'full' mode"
    echo ""
fi

echo -e "${CYAN}🌟 Observatory deployment completed successfully!${NC}"
echo -e "${CYAN}🎉 Welcome to your mission control center!${NC}" 