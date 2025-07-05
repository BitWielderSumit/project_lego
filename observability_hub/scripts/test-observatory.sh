#!/bin/bash

# Observatory Test Script
# Validates the monitoring stack deployment and connectivity

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="observability"
KAFKA_NAMESPACE="kafka"

echo -e "${CYAN}🔍 Observatory System Diagnostics${NC}"
echo -e "${CYAN}===================================${NC}"
echo ""

# Test 1: Check if namespace exists
echo -e "${YELLOW}📋 Test 1: Checking observatory namespace...${NC}"
if kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✅ Namespace '${NAMESPACE}' exists${NC}"
else
    echo -e "${RED}❌ Namespace '${NAMESPACE}' not found${NC}"
    exit 1
fi

# Test 2: Check pod status
echo -e "${YELLOW}📋 Test 2: Checking pod status...${NC}"
PODS_NOT_READY=0

# Check Prometheus pods
if kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=prometheus &> /dev/null; then
    PROMETHEUS_READY=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    if [ "$PROMETHEUS_READY" = "true" ]; then
        echo -e "${GREEN}✅ Prometheus is ready${NC}"
    else
        echo -e "${RED}❌ Prometheus is not ready${NC}"
        PODS_NOT_READY=$((PODS_NOT_READY + 1))
    fi
else
    echo -e "${RED}❌ Prometheus pods not found${NC}"
    PODS_NOT_READY=$((PODS_NOT_READY + 1))
fi

# Check Grafana pods
if kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=grafana &> /dev/null; then
    GRAFANA_READY=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    if [ "$GRAFANA_READY" = "true" ]; then
        echo -e "${GREEN}✅ Grafana is ready${NC}"
    else
        echo -e "${RED}❌ Grafana is not ready${NC}"
        PODS_NOT_READY=$((PODS_NOT_READY + 1))
    fi
else
    echo -e "${RED}❌ Grafana pods not found${NC}"
    PODS_NOT_READY=$((PODS_NOT_READY + 1))
fi

# Check AlertManager pods
if kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=alertmanager &> /dev/null; then
    ALERTMANAGER_READY=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=alertmanager -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    if [ "$ALERTMANAGER_READY" = "true" ]; then
        echo -e "${GREEN}✅ AlertManager is ready${NC}"
    else
        echo -e "${RED}❌ AlertManager is not ready${NC}"
        PODS_NOT_READY=$((PODS_NOT_READY + 1))
    fi
else
    echo -e "${RED}❌ AlertManager pods not found${NC}"
    PODS_NOT_READY=$((PODS_NOT_READY + 1))
fi

# Test 3: Check services
echo -e "${YELLOW}📋 Test 3: Checking service endpoints...${NC}"
SERVICES_MISSING=0

# Check Prometheus service
if kubectl get svc -n ${NAMESPACE} prometheus-operated &> /dev/null; then
    echo -e "${GREEN}✅ Prometheus service exists${NC}"
else
    echo -e "${RED}❌ Prometheus service not found${NC}"
    SERVICES_MISSING=$((SERVICES_MISSING + 1))
fi

# Check Grafana service
GRAFANA_SERVICE=$(kubectl get svc -n ${NAMESPACE} -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$GRAFANA_SERVICE" ]; then
    echo -e "${GREEN}✅ Grafana service exists: ${GRAFANA_SERVICE}${NC}"
else
    echo -e "${RED}❌ Grafana service not found${NC}"
    SERVICES_MISSING=$((SERVICES_MISSING + 1))
fi

# Check AlertManager service
if kubectl get svc -n ${NAMESPACE} alertmanager-operated &> /dev/null; then
    echo -e "${GREEN}✅ AlertManager service exists${NC}"
else
    echo -e "${RED}❌ AlertManager service not found${NC}"
    SERVICES_MISSING=$((SERVICES_MISSING + 1))
fi

# Test 4: Check ServiceMonitors
echo -e "${YELLOW}📋 Test 4: Checking ServiceMonitors...${NC}"
SERVICEMONITORS=$(kubectl get servicemonitor -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
if [ "$SERVICEMONITORS" -gt 0 ]; then
    echo -e "${GREEN}✅ Found ${SERVICEMONITORS} ServiceMonitor(s)${NC}"
    kubectl get servicemonitor -n ${NAMESPACE} --no-headers 2>/dev/null | while read line; do
        echo -e "${BLUE}   📊 ${line}${NC}"
    done
else
    echo -e "${YELLOW}⚠️  No ServiceMonitors found${NC}"
fi

# Test 5: Check PrometheusRules
echo -e "${YELLOW}📋 Test 5: Checking PrometheusRules...${NC}"
PROMETHEUSRULES=$(kubectl get prometheusrule -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l)
if [ "$PROMETHEUSRULES" -gt 0 ]; then
    echo -e "${GREEN}✅ Found ${PROMETHEUSRULES} PrometheusRule(s)${NC}"
    kubectl get prometheusrule -n ${NAMESPACE} --no-headers 2>/dev/null | while read line; do
        echo -e "${BLUE}   🚨 ${line}${NC}"
    done
else
    echo -e "${YELLOW}⚠️  No PrometheusRules found${NC}"
fi

# Test 6: Check Kafka integration
echo -e "${YELLOW}📋 Test 6: Checking Kafka integration...${NC}"
if kubectl get namespace ${KAFKA_NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✅ Kafka namespace exists${NC}"
    
    # Check if Kafka pods are running
    KAFKA_PODS=$(kubectl get pods -n ${KAFKA_NAMESPACE} -l app.kubernetes.io/name=kafka --no-headers 2>/dev/null | wc -l)
    if [ "$KAFKA_PODS" -gt 0 ]; then
        echo -e "${GREEN}✅ Found ${KAFKA_PODS} Kafka pod(s)${NC}"
        
        # Check if Kafka metrics service exists
        if kubectl get svc -n ${KAFKA_NAMESPACE} -l component=metrics &> /dev/null; then
            echo -e "${GREEN}✅ Kafka metrics service found${NC}"
        else
            echo -e "${YELLOW}⚠️  Kafka metrics service not found${NC}"
            echo -e "${YELLOW}   💡 Run observatory deployment with 'full' mode to integrate Kafka monitoring${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No Kafka pods found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Kafka namespace not found${NC}"
    echo -e "${YELLOW}   💡 Deploy Kafka first for full integration${NC}"
fi

# Test 7: Connectivity Tests
echo -e "${YELLOW}📋 Test 7: Testing connectivity...${NC}"

# Test Prometheus connectivity
echo -e "${BLUE}   🔍 Testing Prometheus connectivity...${NC}"
if kubectl port-forward svc/prometheus-operated 9090:9090 -n ${NAMESPACE} &> /dev/null &
then
    PROMETHEUS_PF_PID=$!
    sleep 3
    
    if curl -s http://localhost:9090/api/v1/query?query=up &> /dev/null; then
        echo -e "${GREEN}   ✅ Prometheus API is accessible${NC}"
        
        # Test if Prometheus is scraping targets
        TARGETS=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets | length' 2>/dev/null || echo "0")
        if [ "$TARGETS" -gt 0 ]; then
            echo -e "${GREEN}   ✅ Prometheus is scraping ${TARGETS} target(s)${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Prometheus has no active targets${NC}"
        fi
    else
        echo -e "${RED}   ❌ Prometheus API is not accessible${NC}"
    fi
    
    kill $PROMETHEUS_PF_PID 2>/dev/null || true
else
    echo -e "${RED}   ❌ Cannot port-forward to Prometheus${NC}"
fi

# Test Grafana connectivity
echo -e "${BLUE}   📊 Testing Grafana connectivity...${NC}"
if kubectl port-forward svc/${GRAFANA_SERVICE} 3000:3000 -n ${NAMESPACE} &> /dev/null &
then
    GRAFANA_PF_PID=$!
    sleep 3
    
    if curl -s http://localhost:3000/api/health &> /dev/null; then
        echo -e "${GREEN}   ✅ Grafana API is accessible${NC}"
    else
        echo -e "${RED}   ❌ Grafana API is not accessible${NC}"
    fi
    
    kill $GRAFANA_PF_PID 2>/dev/null || true
else
    echo -e "${RED}   ❌ Cannot port-forward to Grafana${NC}"
fi

# Test 8: Resource Usage
echo -e "${YELLOW}📋 Test 8: Checking resource usage...${NC}"
if kubectl top pods -n ${NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✅ Resource metrics available${NC}"
    kubectl top pods -n ${NAMESPACE} --no-headers | while read line; do
        echo -e "${BLUE}   📈 ${line}${NC}"
    done
else
    echo -e "${YELLOW}⚠️  Resource metrics not available (metrics-server might not be installed)${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}📊 Diagnostic Summary${NC}"
echo -e "${CYAN}====================${NC}"

TOTAL_ISSUES=$((PODS_NOT_READY + SERVICES_MISSING))

if [ "$TOTAL_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}🎉 All systems operational! Observatory is ready for mission control.${NC}"
    echo ""
    echo -e "${BLUE}🎯 Next Steps:${NC}"
    echo "1. Access Grafana dashboard:"
    echo "   kubectl port-forward svc/${GRAFANA_SERVICE} 3000:3000 -n ${NAMESPACE}"
    echo "   URL: http://localhost:3000"
    echo "   Username: admin | Password: observatory-admin"
    echo ""
    echo "2. Access Prometheus:"
    echo "   kubectl port-forward svc/prometheus-operated 9090:9090 -n ${NAMESPACE}"
    echo "   URL: http://localhost:9090"
    echo ""
    echo "3. Import Kafka dashboards and configure alerts as needed"
else
    echo -e "${RED}⚠️  Found ${TOTAL_ISSUES} issue(s) that need attention:${NC}"
    if [ "$PODS_NOT_READY" -gt 0 ]; then
        echo -e "${RED}   - ${PODS_NOT_READY} pod(s) not ready${NC}"
    fi
    if [ "$SERVICES_MISSING" -gt 0 ]; then
        echo -e "${RED}   - ${SERVICES_MISSING} service(s) missing${NC}"
    fi
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo "1. Check pod logs: kubectl logs -n ${NAMESPACE} <pod-name>"
    echo "2. Check events: kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp'"
    echo "3. Re-run deployment: ./observability_hub/scripts/deploy-observatory.sh"
fi

echo ""
echo -e "${CYAN}🔭 Observatory diagnostics completed!${NC}" 