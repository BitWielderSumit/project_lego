# Kafka Comprehensive Monitoring Guide

## Overview
This guide explains all the metrics available in the **Kafka Comprehensive Monitoring** dashboard, which provides extensive monitoring capabilities for Kafka clusters using JMX metrics.

## Dashboard Sections

### 1. Cluster Health (Top Row Stats)
These stat panels provide a quick overview of cluster health:

#### **Active Brokers**
- **Metric**: `kafka_controller_kafkacontroller_activebrokercount_value`
- **Description**: Number of active brokers in the cluster
- **Healthy**: Should match your expected broker count
- **Alert**: Red if 0 (critical failure)

#### **Total Topics**
- **Metric**: `kafka_controller_kafkacontroller_globaltopiccount_value`
- **Description**: Total number of topics in the cluster
- **Use**: Track topic growth over time

#### **Total Partitions**
- **Metric**: `kafka_controller_kafkacontroller_globalpartitioncount_value`
- **Description**: Total number of partitions across all topics
- **Use**: Monitor partition distribution and growth

#### **Offline Partitions**
- **Metric**: `kafka_controller_kafkacontroller_offlinepartitionscount_value`
- **Description**: Number of partitions that are offline
- **Healthy**: Should always be 0
- **Alert**: Red if ≥ 1 (critical issue)

#### **Under Replicated Partitions**
- **Metric**: `kafka_server_replicamanager_underreplicatedpartitions_value`
- **Description**: Number of partitions that don't have enough replicas
- **Healthy**: Should be 0
- **Alert**: Yellow if ≥ 1, Red if ≥ 10

#### **Leader Count**
- **Metric**: `kafka_server_replicamanager_leadercount_value`
- **Description**: Number of partition leaders on this broker
- **Use**: Monitor leader distribution across brokers

#### **ISR Shrinks**
- **Metric**: `increase(kafka_server_replicamanager_isrshrinks_total[1h])`
- **Description**: Rate of In-Sync Replica set shrinkage
- **Healthy**: Should be minimal
- **Alert**: High rates indicate replication issues

#### **ISR Expands**
- **Metric**: `increase(kafka_server_replicamanager_isrexpands_total[1h])`
- **Description**: Rate of In-Sync Replica set expansion
- **Use**: Should balance with ISR shrinks

### 2. Throughput Metrics

#### **Messages In Rate**
- **Metric**: `rate(kafka_server_brokertopicmetrics_messagesin_total[5m])`
- **Description**: Rate of messages being produced to topics
- **Unit**: Messages per second
- **Use**: Monitor production load and identify busy topics

#### **Bytes In Rate**
- **Metric**: `rate(kafka_server_brokertopicmetrics_bytesin_total[5m])`
- **Description**: Rate of bytes being produced to topics
- **Unit**: Bytes per second
- **Use**: Monitor data volume and network utilization

#### **Messages Out Rate**
- **Metric**: `rate(kafka_server_brokertopicmetrics_messagesout_total[5m])`
- **Description**: Rate of messages being consumed from topics
- **Unit**: Messages per second
- **Use**: Monitor consumption rate and identify popular topics

#### **Bytes Out Rate**
- **Metric**: `rate(kafka_server_brokertopicmetrics_bytesout_total[5m])`
- **Description**: Rate of bytes being consumed from topics
- **Unit**: Bytes per second
- **Use**: Monitor data consumption patterns

### 3. Consumer Lag Monitoring

#### **Consumer Lag (Estimate)**
- **Metric**: `kafka_server_brokertopicmetrics_messagesin_total - kafka_server_brokertopicmetrics_messagesout_total`
- **Description**: Rough estimate of consumer lag based on message counts
- **Note**: This is an approximation; actual consumer lag requires consumer group metrics
- **Use**: Early warning for potential consumer issues

### 4. Request Processing Metrics

#### **Request Rate**
- **Metric**: `rate(kafka_network_requestmetrics_requestspersec_count[5m])`
- **Description**: Rate of requests by type (Produce, Fetch, Metadata, etc.)
- **Unit**: Requests per second
- **Use**: Monitor API usage patterns

#### **Request Latency (99th Percentile)**
- **Metric**: `kafka_network_requestmetrics_totaltimems{quantile="0.99"}`
- **Description**: 99th percentile request processing time
- **Unit**: Milliseconds
- **Use**: Monitor request performance and identify bottlenecks

#### **Request Queue Size**
- **Metric**: `kafka_network_requestchannel_requestqueuesize_value`
- **Description**: Number of requests waiting in the request queue
- **Healthy**: Should be low (< 10)
- **Alert**: High values indicate broker overload

### 5. Network and Resource Metrics

#### **Network Processor Idle %**
- **Metric**: `kafka_network_processor_idlepercent_value`
- **Description**: Percentage of time network processors are idle
- **Healthy**: Should be > 50%
- **Alert**: Low values indicate network saturation

#### **Log Size by Topic**
- **Metric**: `kafka_log_log_size`
- **Description**: Total size of log files per topic/partition
- **Unit**: Bytes
- **Use**: Monitor disk usage and topic growth

### 6. JVM Health Metrics

#### **JVM Memory Usage**
- **Metrics**: 
  - `kafka_java_lang_memory_heapmemoryusage_used`
  - `kafka_java_lang_memory_heapmemoryusage_max`
- **Description**: JVM heap memory usage
- **Unit**: Bytes
- **Use**: Monitor memory consumption and potential memory issues

#### **JVM GC Activity**
- **Metric**: `rate(kafka_java_lang_garbagecollector_collectiontime_total[5m])`
- **Description**: Rate of time spent in garbage collection
- **Unit**: Milliseconds per second
- **Use**: Monitor JVM health and GC pressure

### 7. Controller and Error Metrics

#### **Controller Elections**
- **Metric**: `increase(kafka_controller_kafkacontroller_controllerchangerate_total[1h])`
- **Description**: Rate of controller elections
- **Healthy**: Should be very low (rare events)
- **Alert**: High rates indicate cluster instability

#### **Failed Requests**
- **Metric**: `rate(kafka_network_requestmetrics_errorspersec_count[5m])`
- **Description**: Rate of failed requests by type
- **Unit**: Errors per second
- **Use**: Monitor error rates and identify problematic operations

## Metric Availability Notes

### JMX Exporter vs Kafka Exporter
This dashboard uses **JMX exporter** metrics (from Bitnami Kafka), not `kafka-exporter` metrics. The key differences:

- **JMX Exporter**: Provides direct JVM and Kafka JMX metrics
- **Kafka Exporter**: Provides consumer group lag metrics via Kafka API

### Missing Consumer Group Metrics
For detailed consumer group lag monitoring, you would need to add `kafka-exporter` to your setup:

```yaml
# Add to your monitoring setup
kafka-exporter:
  enabled: true
  kafkaServer: "kafka-local:9092"
  serviceMonitor:
    enabled: true
```

### Alternative Consumer Lag Monitoring
Without `kafka-exporter`, you can:
1. Use the message in/out difference (rough estimate)
2. Monitor consumer applications directly
3. Use Kafka's built-in consumer group commands

## Alerting Recommendations

### Critical Alerts
- **Offline Partitions** > 0
- **Active Brokers** = 0
- **Under Replicated Partitions** > 0

### Warning Alerts
- **ISR Shrinks** > 5/hour
- **Request Latency** > 1000ms
- **Request Queue Size** > 10
- **Network Processor Idle** < 30%

### Information Alerts
- **Controller Elections** > 1/hour
- **High Throughput** > 1000 msg/sec
- **GC Time** > 100ms/sec

## Dashboard Usage Tips

### Time Range Selection
- **Real-time monitoring**: Use 5-15 minute windows
- **Trend analysis**: Use 1-24 hour windows
- **Capacity planning**: Use 1-7 day windows

### Filtering
- Use the topic filter to focus on specific topics
- Use the instance filter to focus on specific brokers
- Combine multiple filters for detailed analysis

### Troubleshooting Workflow
1. **Check cluster health** (top row stats)
2. **Review throughput patterns** (message/byte rates)
3. **Examine request performance** (latency, queue sizes)
4. **Monitor resource utilization** (network, JVM)
5. **Investigate errors** (failed requests, controller elections)

## Next Steps

### Enhanced Monitoring
1. Add `kafka-exporter` for consumer group metrics
2. Add JVM heap dump analysis
3. Add disk I/O metrics
4. Add network interface metrics

### Integration
1. Connect to alerting systems (AlertManager, PagerDuty)
2. Add runbooks for common issues
3. Create automated remediation workflows
4. Integrate with capacity planning tools

## Troubleshooting Common Issues

### High Consumer Lag
1. Check consumer application health
2. Verify consumer group configuration
3. Monitor network connectivity
4. Check for processing bottlenecks

### Under Replicated Partitions
1. Check broker health
2. Verify network connectivity between brokers
3. Check disk space and I/O performance
4. Review replication configuration

### High Request Latency
1. Check broker resource utilization
2. Monitor network performance
3. Review request queue sizes
4. Check for GC pressure

This comprehensive dashboard provides visibility into all aspects of Kafka health and performance, enabling proactive monitoring and quick troubleshooting of issues. 