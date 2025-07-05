#!/usr/bin/env python3
"""
ATM Transaction Consumer for Kafka

Consumes ATM transaction messages from Kafka and displays them
on the console with optional filtering and formatting.
"""

import json
import time
import logging
import signal
import sys
from typing import Dict, Optional
import yaml
from kafka import KafkaConsumer
from kafka.errors import KafkaError
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ATMTransactionConsumer:
    def __init__(self, config_path: str = '/app/config/consumer-config.yaml'):
        """Initialize the ATM transaction consumer."""
        self.config = self._load_config(config_path)
        self.consumer = None
        self.running = False
        self.total_consumed = 0
        self.stats = {
            'total_messages': 0,
            'messages_by_status': {},
            'messages_by_type': {},
            'messages_by_region': {},
            'total_amount': 0.0
        }
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _load_config(self, config_path: str) -> Dict:
        """Load configuration from YAML file."""
        try:
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
                logger.info(f"Configuration loaded from {config_path}")
                return config
        except FileNotFoundError:
            logger.warning(f"Config file not found: {config_path}, using defaults")
            return self._get_default_config()
        except Exception as e:
            logger.error(f"Error loading config: {e}")
            return self._get_default_config()
    
    def _get_default_config(self) -> Dict:
        """Get default configuration."""
        return {
            'kafka': {
                'bootstrap_servers': 'kafka-local.kafka.svc.cluster.local:9092',
                'topic': 'atm-transactions',
                'group_id': 'atm-consumer-group',
                'auto_offset_reset': 'latest'
            },
            'consumer': {
                'display_format': 'detailed',  # 'detailed', 'compact', 'json'
                'show_stats': True,
                'stats_interval': 100,
                'filter_by_status': None,  # None or list of status codes
                'filter_by_region': None   # None or list of regions
            }
        }
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals."""
        logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.stop_consuming()
        sys.exit(0)
    
    def _create_consumer(self) -> KafkaConsumer:
        """Create and configure Kafka consumer."""
        return KafkaConsumer(
            self.config['kafka']['topic'],
            bootstrap_servers=self.config['kafka']['bootstrap_servers'],
            group_id=self.config['kafka']['group_id'],
            auto_offset_reset=self.config['kafka']['auto_offset_reset'],
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            key_deserializer=lambda k: k.decode('utf-8') if k else None,
            enable_auto_commit=True,
            auto_commit_interval_ms=1000,
            max_poll_records=100
        )
    
    def _update_stats(self, transaction: Dict):
        """Update consumption statistics."""
        self.stats['total_messages'] += 1
        
        # Status statistics
        status = transaction.get('status_code', 'UNKNOWN')
        self.stats['messages_by_status'][status] = self.stats['messages_by_status'].get(status, 0) + 1
        
        # Transaction type statistics
        tx_type = transaction.get('transaction_type', 'UNKNOWN')
        self.stats['messages_by_type'][tx_type] = self.stats['messages_by_type'].get(tx_type, 0) + 1
        
        # Region statistics
        region = transaction.get('region_id', 'UNKNOWN')
        self.stats['messages_by_region'][region] = self.stats['messages_by_region'].get(region, 0) + 1
        
        # Amount statistics (only for successful transactions)
        if status == 'SUCCESS' and transaction.get('amount', 0) > 0:
            self.stats['total_amount'] += transaction.get('amount', 0)
    
    def _should_process_message(self, transaction: Dict) -> bool:
        """Check if message should be processed based on filters."""
        # Filter by status
        status_filter = self.config['consumer'].get('filter_by_status')
        if status_filter and transaction.get('status_code') not in status_filter:
            return False
        
        # Filter by region
        region_filter = self.config['consumer'].get('filter_by_region')
        if region_filter and transaction.get('region_id') not in region_filter:
            return False
            
        return True
    
    def _format_transaction(self, transaction: Dict, format_type: str = 'detailed') -> str:
        """Format transaction for display."""
        if format_type == 'json':
            return json.dumps(transaction, indent=2)
        elif format_type == 'compact':
            return (f"[{transaction.get('timestamp', 'N/A')}] "
                   f"{transaction.get('transaction_type', 'N/A')} "
                   f"${transaction.get('amount', 0):.2f} "
                   f"({transaction.get('status_code', 'N/A')}) "
                   f"ATM:{transaction.get('atm_id', 'N/A')} "
                   f"Region:{transaction.get('region_id', 'N/A')}")
        else:  # detailed
            return self._format_detailed_transaction(transaction)
    
    def _format_detailed_transaction(self, transaction: Dict) -> str:
        """Format transaction in detailed view."""
        lines = [
            "=" * 80,
            f"🏧 ATM TRANSACTION - {transaction.get('transaction_id', 'N/A')}",
            "=" * 80,
            f"📍 ATM ID:           {transaction.get('atm_id', 'N/A')}",
            f"🌍 Region:           {transaction.get('region_id', 'N/A')}",
            f"📍 Location:         {transaction.get('location', 'N/A')}",
            f"💳 Transaction Type: {transaction.get('transaction_type', 'N/A')}",
            f"💰 Amount:           ${transaction.get('amount', 0):.2f} {transaction.get('currency', 'USD')}",
            f"✅ Status:           {transaction.get('status_code', 'N/A')}",
            f"👤 User ID:          {transaction.get('user_id', 'N/A')}",
            f"💳 Card Number:      {transaction.get('card_number', 'N/A')}",
            f"⏰ Timestamp:        {transaction.get('timestamp', 'N/A')}",
            "=" * 80
        ]
        return "\n".join(lines)
    
    def _display_stats(self):
        """Display consumption statistics."""
        print("\n" + "="*60)
        print("📊 ATM TRANSACTION STATISTICS")
        print("="*60)
        print(f"Total Messages Consumed: {self.stats['total_messages']}")
        print(f"Total Transaction Amount: ${self.stats['total_amount']:.2f}")
        
        print("\n📈 Status Distribution:")
        for status, count in sorted(self.stats['messages_by_status'].items()):
            percentage = (count / self.stats['total_messages']) * 100 if self.stats['total_messages'] > 0 else 0
            print(f"  {status}: {count} ({percentage:.1f}%)")
        
        print("\n🔄 Transaction Type Distribution:")
        for tx_type, count in sorted(self.stats['messages_by_type'].items()):
            percentage = (count / self.stats['total_messages']) * 100 if self.stats['total_messages'] > 0 else 0
            print(f"  {tx_type}: {count} ({percentage:.1f}%)")
        
        print("\n🌍 Region Distribution:")
        for region, count in sorted(self.stats['messages_by_region'].items()):
            percentage = (count / self.stats['total_messages']) * 100 if self.stats['total_messages'] > 0 else 0
            print(f"  {region}: {count} ({percentage:.1f}%)")
        
        print("="*60)
    
    def start_consuming(self):
        """Start consuming ATM transactions."""
        if self.running:
            logger.warning("Consumer is already running")
            return
            
        try:
            self.consumer = self._create_consumer()
            self.running = True
            
            logger.info("ATM Transaction Consumer started")
            logger.info(f"Consuming from topic: {self.config['kafka']['topic']}")
            logger.info(f"Consumer group: {self.config['kafka']['group_id']}")
            logger.info(f"Display format: {self.config['consumer']['display_format']}")
            
            # Show filters if any
            if self.config['consumer'].get('filter_by_status'):
                logger.info(f"Status filter: {self.config['consumer']['filter_by_status']}")
            if self.config['consumer'].get('filter_by_region'):
                logger.info(f"Region filter: {self.config['consumer']['filter_by_region']}")
            
            print("\n🎯 Waiting for ATM transactions...")
            print("Press Ctrl+C to stop consuming\n")
            
            # Consume messages
            for message in self.consumer:
                if not self.running:
                    break
                    
                try:
                    transaction = message.value
                    
                    # Check if message should be processed
                    if not self._should_process_message(transaction):
                        continue
                    
                    # Update statistics
                    self._update_stats(transaction)
                    
                    # Display transaction
                    formatted_transaction = self._format_transaction(
                        transaction, 
                        self.config['consumer']['display_format']
                    )
                    print(formatted_transaction)
                    
                    # Display statistics periodically
                    if (self.config['consumer']['show_stats'] and 
                        self.stats['total_messages'] % self.config['consumer']['stats_interval'] == 0):
                        self._display_stats()
                        
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    continue
                    
        except KeyboardInterrupt:
            logger.info("Received interrupt signal, stopping consumer...")
        except Exception as e:
            logger.error(f"Failed to start consumer: {e}")
        finally:
            self.stop_consuming()
    
    def stop_consuming(self):
        """Stop consuming messages."""
        if not self.running:
            return
            
        self.running = False
        if self.consumer:
            logger.info("Closing consumer...")
            self.consumer.close()
            
        # Display final statistics
        if self.config['consumer']['show_stats']:
            self._display_stats()
            
        logger.info(f"Consumer stopped. Total messages consumed: {self.stats['total_messages']}")

def main():
    """Main function to run the consumer."""
    consumer = ATMTransactionConsumer()
    
    try:
        consumer.start_consuming()
    except KeyboardInterrupt:
        logger.info("Shutting down consumer...")
    except Exception as e:
        logger.error(f"Consumer error: {e}")
    finally:
        consumer.stop_consuming()

if __name__ == "__main__":
    main() 