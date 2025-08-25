#!/usr/bin/env python3

from st2common.runners.base_action import Action
import json
from datetime import datetime

class ExtractDataAction(Action):
    def run(self):
        """Simulate data extraction"""
        self.logger.info("Starting data extraction...")
        
        data = {
            'timestamp': datetime.now().isoformat(),
            'records': [
                {'id': 1, 'name': 'Alice', 'score': 85},
                {'id': 2, 'name': 'Bob', 'score': 92},
                {'id': 3, 'name': 'Charlie', 'score': 78}
            ]
        }
        
        self.logger.info(f"Extracted {len(data['records'])} records")
        return (True, data)