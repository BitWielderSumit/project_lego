#!/usr/bin/env python3
"""
ATM Transaction Producer for Kafka

Generates realistic ATM transaction messages and sends them to Kafka
at configurable rates.
"""

import json
import time
import random
import uuid
from datetime import datetime
from typing import Dict, List
import logging
import os
import yaml
from kafka import KafkaProducer
from kafka.errors import KafkaError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ATMTransactionProducer:
    def __init__(self, config_path: str = '/app/config/producer-config.yaml'):
        """Initialize the ATM transaction producer."""
        self.config = self._load_config(config_path)
        self.producer = None
        self.running = False
        self.total_sent = 0
        self.start_time = None
        
        # Sample data for realistic transactions
        self.atm_ids = [f"ATM-{i:04d}" for i in range(1, 101)]
        self.region_ids = ["US-WEST", "US-EAST", "US-CENTRAL", "EU-WEST", "EU-CENTRAL", "APAC"]
        self.status_codes = {
            "SUCCESS": 0.85,
            "FAILED": 0.08,
            "TIMEOUT": 0.04,
            "INSUFFICIENT_FUNDS": 0.02,
            "CARD_BLOCKED": 0.01
        }
        self.transaction_types = {
            "WITHDRAWAL": 0.60,
            "BALANCE_INQUIRY": 0.25,
            "DEPOSIT": 0.10,
            "TRANSFER": 0.05
        }
        self.currencies = ["USD", "EUR", "GBP", "JPY", "CAD"]
        self.locations = [
            "Downtown Branch", "Mall Center", "Airport Terminal", 
            "University Campus", "Shopping Center", "Bank Branch",
            "Gas Station", "Grocery Store", "Hotel Lobby", "Train Station"
        ]
        
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
                'topic': 'atm-transactions'
            },
            'producer': {
                'rate': 5,  # messages per second
                'burst_mode': False,
                'batch_size': 100
            }
        }
    
    def _weighted_choice(self, choices: Dict[str, float]) -> str:
        """Make a weighted random choice."""
        total = sum(choices.values())
        r = random.uniform(0, total)
        upto = 0
        for choice, weight in choices.items():
            if upto + weight >= r:
                return choice
            upto += weight
        return list(choices.keys())[-1]
    
    def _generate_transaction(self) -> Dict:
        """Generate a realistic ATM transaction."""
        transaction_id = str(uuid.uuid4())
        atm_id = random.choice(self.atm_ids)
        region_id = random.choice(self.region_ids)
        transaction_type = self._weighted_choice(self.transaction_types)
        status_code = self._weighted_choice(self.status_codes)
        
        # Generate amount based on transaction type
        if transaction_type == "WITHDRAWAL":
            amount = round(random.uniform(20, 500), 2)
        elif transaction_type == "DEPOSIT":
            amount = round(random.uniform(50, 1000), 2)
        elif transaction_type == "TRANSFER":
            amount = round(random.uniform(100, 2000), 2)
        else:  # BALANCE_INQUIRY
            amount = 0.0
        
        # Generate user and card data
        user_id = f"USER-{random.randint(10000, 99999)}"
        card_number = f"****-****-****-{random.randint(1000, 9999)}"
        
        # Other fields
        location = random.choice(self.locations)
        currency = random.choice(self.currencies)
        timestamp = datetime.utcnow().isoformat() + "Z"
        
        return {
            "transaction_id": transaction_id,
            "atm_id": atm_id,
            "region_id": region_id,
            "amount": amount,
            "status_code": status_code,
            "user_id": user_id,
            "card_number": card_number,
            "transaction_type": transaction_type,
            "location": location,
            "currency": currency,
            "timestamp": timestamp
        }
    
    def _create_producer(self) -> KafkaProducer:
        """Create and configure Kafka producer."""
        return KafkaProducer(
            bootstrap_servers=self.config['kafka']['bootstrap_servers'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None,
            acks='all',
            retries=3,
            batch_size=16384,
            linger_ms=10
        )
    
    def _delivery_callback(self, msg):
        """Callback for message delivery."""
        if msg.exception:
            logger.error(f"Message delivery failed: {msg.exception}")
        else:
            self.total_sent += 1
            if self.total_sent % 100 == 0:
                logger.info(f"Successfully sent {self.total_sent} messages")
    
    def start_producing(self):
        """Start producing ATM transactions."""
        if self.running:
            logger.warning("Producer is already running")
            return
            
        try:
            self.producer = self._create_producer()
            self.running = True
            self.start_time = time.time()
            
            logger.info("ATM Transaction Producer started")
            logger.info(f"Producing to topic: {self.config['kafka']['topic']}")
            logger.info(f"Rate: {self.config['producer']['rate']} messages/second")
            
            rate = self.config['producer']['rate']
            interval = 1.0 / rate if rate > 0 else 1.0
            
            while self.running:
                try:
                    # Generate transaction
                    transaction = self._generate_transaction()
                    
                    # Use ATM ID as key for partitioning
                    key = transaction['atm_id']
                    
                    # Send message
                    future = self.producer.send(
                        self.config['kafka']['topic'],
                        key=key,
                        value=transaction
                    )
                    
                    # Track successful sends
                    self.total_sent += 1
                    
                    # Log sample transactions
                    if self.total_sent % 500 == 0:
                        logger.info(f"Sample transaction: {json.dumps(transaction, indent=2)}")
                    
                    # Control rate
                    if not self.config['producer'].get('burst_mode', False):
                        time.sleep(interval)
                        
                except KeyboardInterrupt:
                    logger.info("Received interrupt signal, stopping producer...")
                    break
                except Exception as e:
                    logger.error(f"Error producing message: {e}")
                    time.sleep(1)
                    
        except Exception as e:
            logger.error(f"Failed to start producer: {e}")
        finally:
            self.stop_producing()
    
    def stop_producing(self):
        """Stop producing messages."""
        if not self.running:
            return
            
        self.running = False
        if self.producer:
            logger.info("Flushing remaining messages...")
            self.producer.flush()
            self.producer.close()
            
        # Log final statistics
        if self.start_time:
            elapsed_time = time.time() - self.start_time
            logger.info(f"Producer stopped after {elapsed_time:.1f} seconds")
            if elapsed_time > 0:
                avg_rate = self.total_sent / elapsed_time
                logger.info(f"Average production rate: {avg_rate:.2f} messages/second")
        
        logger.info(f"Total messages sent: {self.total_sent}")

def main():
    """Main function to run the producer."""
    producer = ATMTransactionProducer()
    
    try:
        producer.start_producing()
    except KeyboardInterrupt:
        logger.info("Shutting down producer...")
    except Exception as e:
        logger.error(f"Producer error: {e}")
    finally:
        producer.stop_producing()

if __name__ == "__main__":
    main() 