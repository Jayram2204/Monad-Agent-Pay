"""
Bayesian Gas Optimizer for Monad Network
Implements G_opt = μ(G_est) + 2⋅σ(G_hist) to eliminate deadweight gas
"""

import numpy as np
from typing import List, Optional, Tuple
from dataclasses import dataclass
from abc import ABC, abstractmethod
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class GasEstimate:
    """Represents a gas estimate with confidence metrics"""
    estimated_gas: int
    confidence_interval: Tuple[int, int]
    timestamp: float
    transaction_type: str

class GasHistory:
    """Manages historical gas data for statistical analysis"""
    
    def __init__(self, max_history: int = 1000):
        self.max_history = max_history
        self.history: List[int] = []
        self.transaction_types: List[str] = []
        
    def add_gas_usage(self, gas_used: int, transaction_type: str = "default"):
        """Add gas usage to history"""
        self.history.append(gas_used)
        self.transaction_types.append(transaction_type)
        
        # Maintain maximum history size
        if len(self.history) > self.max_history:
            self.history.pop(0)
            self.transaction_types.pop(0)
            
    def get_gas_for_type(self, transaction_type: str) -> List[int]:
        """Get gas history for specific transaction type"""
        return [gas for gas, tx_type in zip(self.history, self.transaction_types) 
                if tx_type == transaction_type]
    
    def get_statistics(self, transaction_type: Optional[str] = None) -> Tuple[float, float]:
        """Calculate mean and standard deviation"""
        if transaction_type:
            gas_data = self.get_gas_for_type(transaction_type)
        else:
            gas_data = self.history
            
        if len(gas_data) < 2:
            # Return default values if insufficient data
            return 21000, 10000  # Default gas + reasonable std dev
            
        mean = float(np.mean(gas_data))
        std_dev = float(np.std(gas_data))
        
        return mean, std_dev

class BayesianGasOptimizer:
    """Implements Bayesian gas optimization using G_opt = μ(G_est) + 2⋅σ(G_hist)"""
    
    def __init__(self, history_size: int = 1000):
        self.history = GasHistory(history_size)
        self.estimator_cache = {}
        
    def estimate_gas_bayesian(self, 
                            estimated_gas: int, 
                            transaction_type: str = "default",
                            confidence_level: float = 0.95) -> GasEstimate:
        """
        Calculate optimal gas using Bayesian formula: G_opt = μ(G_est) + 2⋅σ(G_hist)
        
        Args:
            estimated_gas: Initial gas estimate from simulation
            transaction_type: Type of transaction for historical context
            confidence_level: Desired confidence level (affects multiplier)
            
        Returns:
            GasEstimate with optimized gas limit and confidence interval
        """
        # Get historical statistics for this transaction type
        hist_mean, hist_std = self.history.get_statistics(transaction_type)
        
        # Calculate Bayesian optimal gas
        # G_opt = μ(G_est) + k⋅σ(G_hist)
        # where k is determined by confidence level
        k = self._get_confidence_multiplier(confidence_level)
        
        # Use estimated gas as μ component
        optimal_gas = int(estimated_gas + k * hist_std)
        
        # Calculate confidence interval
        lower_bound = int(optimal_gas - k * hist_std)
        upper_bound = int(optimal_gas + k * hist_std)
        
        # Ensure minimum gas (at least 21000 for basic transactions)
        optimal_gas = max(optimal_gas, 21000)
        lower_bound = max(lower_bound, 21000)
        upper_bound = max(upper_bound, 21000)
        
        logger.info(f"Bayesian Gas Optimization:")
        logger.info(f"  Estimated: {estimated_gas}")
        logger.info(f"  Historical Mean: {hist_mean:.0f}")
        logger.info(f"  Historical Std Dev: {hist_std:.0f}")
        logger.info(f"  Optimal Gas: {optimal_gas}")
        logger.info(f"  Confidence Interval: [{lower_bound}, {upper_bound}]")
        
        return GasEstimate(
            estimated_gas=optimal_gas,
            confidence_interval=(lower_bound, upper_bound),
            timestamp=0,  # Would be set by caller
            transaction_type=transaction_type
        )
    
    def _get_confidence_multiplier(self, confidence_level: float) -> float:
        """Convert confidence level to standard deviation multiplier"""
        # Standard normal distribution multipliers
        confidence_map = {
            0.68: 1.0,   # 1 standard deviation
            0.90: 1.645, # 90% confidence
            0.95: 2.0,   # 95% confidence (default)
            0.99: 2.576, # 99% confidence
            0.999: 3.291 # 99.9% confidence
        }
        
        # Find closest confidence level
        closest = min(confidence_map.keys(), key=lambda x: abs(x - confidence_level))
        return confidence_map[closest]
    
    def update_history(self, actual_gas_used: int, transaction_type: str = "default"):
        """Update gas history with actual gas usage"""
        self.history.add_gas_usage(actual_gas_used, transaction_type)
        logger.info(f"Updated gas history: {transaction_type} used {actual_gas_used} gas")
        
    def get_optimization_stats(self) -> dict:
        """Get statistics about gas optimization performance"""
        if len(self.history.history) == 0:
            return {"message": "No gas history available"}
            
        total_transactions = len(self.history.history)
        avg_gas = np.mean(self.history.history)
        std_gas = np.std(self.history.history)
        
        return {
            "total_transactions": total_transactions,
            "average_gas_used": float(avg_gas),
            "std_deviation": float(std_gas),
            "gas_efficiency_improvement": self._calculate_efficiency_improvement()
        }
        
    def _calculate_efficiency_improvement(self) -> float:
        """Calculate percentage improvement in gas efficiency"""
        if len(self.history.history) < 10:
            return 0.0
            
        # Compare recent transactions with older ones
        recent = self.history.history[-10:]
        older = self.history.history[-20:-10] if len(self.history.history) >= 20 else [21000] * 10
        
        recent_avg = np.mean(recent)
        older_avg = np.mean(older)
        
        if older_avg > 0:
            improvement = (older_avg - recent_avg) / older_avg * 100
            return float(improvement)
        return 0.0

class AdaptiveGasEstimator:
    """Adaptive gas estimator that learns from transaction outcomes"""
    
    def __init__(self):
        self.optimizer = BayesianGasOptimizer()
        self.success_rate = 0.95  # Target success rate
        self.learning_rate = 0.1
        
    def estimate_adaptive_gas(self, 
                             base_estimate: int,
                             transaction_type: str = "default") -> GasEstimate:
        """Adaptive gas estimation that adjusts based on success rate"""
        
        # Get Bayesian estimate
        bayesian_estimate = self.optimizer.estimate_gas_bayesian(
            base_estimate, transaction_type
        )
        
        # Adjust based on historical success rate
        optimal_gas = bayesian_estimate.estimated_gas
        
        # If success rate is too low, increase gas buffer
        if self.success_rate < 0.90:
            optimal_gas = int(optimal_gas * 1.1)  # 10% increase
        elif self.success_rate > 0.98:
            # If very high success rate, can reduce buffer
            optimal_gas = int(optimal_gas * 0.95)  # 5% reduction
            
        # Update the estimate
        bayesian_estimate.estimated_gas = optimal_gas
        
        return bayesian_estimate
    
    def update_from_transaction_result(self, 
                                      gas_limit: int, 
                                      gas_used: int, 
                                      success: bool,
                                      transaction_type: str = "default"):
        """Update estimator based on transaction outcome"""
        # Update gas history
        self.optimizer.update_history(gas_used, transaction_type)
        
        # Update success rate
        if success:
            # Transaction succeeded
            if gas_used <= gas_limit * 0.9:  # Used less than 90% of limit
                # Good efficiency - slightly increase success rate
                self.success_rate = min(0.99, self.success_rate + self.learning_rate * 0.1)
            else:
                # Close to limit - maintain success rate
                pass
        else:
            # Transaction failed - decrease success rate
            self.success_rate = max(0.80, self.success_rate - self.learning_rate * 0.2)
            
        logger.info(f"Updated success rate: {self.success_rate:.3f}")

# Example usage and testing
def main():
    """Example usage of the Bayesian Gas Optimizer"""
    
    # Initialize optimizer
    optimizer = BayesianGasOptimizer()
    
    # Simulate some historical data
    historical_gas = [25000, 30000, 28000, 35000, 22000, 29000, 31000, 27000]
    for gas in historical_gas:
        optimizer.update_history(gas, "transfer")
    
    # Test gas estimation
    estimated_gas = 28000
    result = optimizer.estimate_gas_bayesian(estimated_gas, "transfer")
    
    print(f"\n=== Bayesian Gas Optimization Results ===")
    print(f"Input estimate: {estimated_gas}")
    print(f"Optimal gas: {result.estimated_gas}")
    print(f"Confidence interval: {result.confidence_interval}")
    print(f"Stats: {optimizer.get_optimization_stats()}")
    
    # Test adaptive estimator
    adaptive = AdaptiveGasEstimator()
    adaptive_result = adaptive.estimate_adaptive_gas(28000, "transfer")
    print(f"\nAdaptive estimate: {adaptive_result.estimated_gas}")
    
    # Simulate transaction success
    adaptive.update_from_transaction_result(30000, 28000, True, "transfer")

if __name__ == "__main__":
    main()