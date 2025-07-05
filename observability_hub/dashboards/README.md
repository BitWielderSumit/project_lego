# Kafka Monitoring Dashboards

## Available Dashboards

### 1. `kafka-jmx-dashboard.json` - Basic Dashboard
- **Purpose**: Simple, focused dashboard with essential Kafka metrics
- **Panels**: 8 panels covering core functionality
- **Best for**: Quick health checks and basic monitoring

**Metrics included**:
- Active Brokers
- Total Topics/Partitions
- Offline Partitions
- Request Rate
- Network Processor Idle %
- Log Size by Topic
- Request Queue Size

### 2. `kafka-comprehensive-dashboard.json` - Enhanced Dashboard ⭐
- **Purpose**: Comprehensive monitoring with advanced metrics
- **Panels**: 22 panels covering all aspects of Kafka health
- **Best for**: Production monitoring, troubleshooting, capacity planning

**Metrics included**:
- **Cluster Health**: Active brokers, topics, partitions, offline partitions
- **Replication Health**: Under-replicated partitions, ISR shrinks/expands, leader count
- **Throughput**: Messages/bytes in and out rates
- **Consumer Lag**: Estimated consumer lag based on message flow
- **Request Processing**: Request rates, latency (99th percentile), queue sizes
- **Network Performance**: Network processor idle percentage
- **JVM Health**: Memory usage, GC activity
- **Controller Metrics**: Controller elections, failed requests
- **Storage**: Log size by topic/partition

## Import Instructions

### Option 1: Import via Grafana UI
1. Open Grafana (localhost:3000)
2. Go to **Dashboards** → **Import**
3. Click **Upload JSON file**
4. Select either dashboard file from this directory
5. Click **Import**

### Option 2: Import via API
```bash
# Import comprehensive dashboard
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @kafka-comprehensive-dashboard.json

# Import basic dashboard
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @kafka-jmx-dashboard.json
```

## Dashboard Selection Guide

### Use Basic Dashboard When:
- ✅ You need quick health checks
- ✅ You want a simple overview
- ✅ You have limited screen space
- ✅ You're new to Kafka monitoring

### Use Comprehensive Dashboard When:
- ✅ You need detailed monitoring
- ✅ You're troubleshooting issues
- ✅ You want to track consumer lag
- ✅ You need JVM and performance metrics
- ✅ You're doing capacity planning
- ✅ You want production-ready monitoring

## Prerequisites

### Required Components
- ✅ Kafka cluster with JMX metrics enabled
- ✅ ServiceMonitor deployed (see `../servicemonitors/kafka-servicemonitor.yaml`)
- ✅ Prometheus collecting Kafka metrics
- ✅ Grafana connected to Prometheus

### Verify Setup
Check that metrics are available:
```bash
# Check if Prometheus is scraping Kafka metrics
curl -s 'http://localhost:9090/api/v1/query?query=kafka_controller_kafkacontroller_activebrokercount_value'

# Should return data like:
# {"status":"success","data":{"resultType":"vector","result":[{"metric":{"instance":"kafka-local-jmx-metrics:5556","job":"kafka-metrics"},"value":[1672531200,"1"]}]}}
```

## Troubleshooting

### Dashboard Shows No Data
1. **Check ServiceMonitor**: Ensure `kafka-servicemonitor.yaml` is deployed
2. **Check Prometheus**: Verify Prometheus is scraping metrics
3. **Check Time Range**: Make sure you're viewing recent data
4. **Check Metric Names**: JMX exporter metric names may vary

### Common Issues

#### "No data points" Error
```bash
# Check if Kafka metrics are available
kubectl get servicemonitor kafka-metrics -n observability
kubectl get pods -n kafka | grep kafka
```

#### Metrics Names Don't Match
Some metrics may have different names depending on your Kafka version:
- `kafka_server_replicamanager_*` might be `kafka_server_replica_manager_*`
- `kafka_java_lang_*` might be `kafka_lang_*`

### Customizing Dashboards

#### Adding New Panels
1. Edit the JSON file
2. Add new panel object to the `panels` array
3. Increment the `id` field
4. Set appropriate `gridPos` for positioning

#### Modifying Queries
1. Find the panel in the JSON
2. Edit the `expr` field in the `targets` array
3. Test the query in Prometheus first

## Additional Resources

- **Comprehensive Guide**: See `kafka-metrics-guide.md` for detailed metric explanations
- **ServiceMonitor**: Located in `../servicemonitors/kafka-servicemonitor.yaml`
- **Kafka Alerts**: See `../alerts/kafka-alerts.yaml` for alerting rules

## Dashboard Layout

### Comprehensive Dashboard Layout
```
Row 1: [Cluster Health Stats - 8 panels in a row]
Row 2: [Messages In Rate] [Bytes In Rate]
Row 3: [Messages Out Rate] [Bytes Out Rate]
Row 4: [Consumer Lag Estimate] [Request Rate]
Row 5: [Request Latency] [Request Queue Size]
Row 6: [Network Processor Idle] [Log Size by Topic]
Row 7: [JVM Memory Usage] [JVM GC Activity]
Row 8: [Controller Elections] [Failed Requests]
```

### Basic Dashboard Layout
```
Row 1: [Active Brokers] [Total Topics] [Total Partitions] [Offline Partitions]
Row 2: [Request Rate] [Network Processor Idle %]
Row 3: [Log Size by Topic] [Request Queue Size]
```

## Next Steps

1. **Import** the comprehensive dashboard
2. **Configure** alerting rules (see `../alerts/`)
3. **Set up** additional monitoring (consumer groups, JVM heap dumps)
4. **Create** custom dashboards for specific use cases
5. **Document** your specific monitoring requirements

## Recommended Refresh Rate
- **Real-time monitoring**: 5-10 seconds
- **General monitoring**: 30 seconds (default)
- **Historical analysis**: 1-5 minutes 