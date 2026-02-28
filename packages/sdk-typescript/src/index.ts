import { MonadClient } from './MonadClient';
import { TransactionBatcher } from './TransactionBatcher';
import { GasOptimizer } from './GasOptimizer';
import { 
  TransactionConfig, 
  BatchConfig, 
  CallType,
  TransactionResult,
  BatchResult
} from './types';

export {
  MonadClient,
  TransactionBatcher,
  GasOptimizer,
  TransactionConfig,
  BatchConfig,
  CallType,
  TransactionResult,
  BatchResult
};

// Main SDK export
export default class MonadSDK {
  private client: MonadClient;
  private batcher: TransactionBatcher;
  private gasOptimizer: GasOptimizer;

  constructor(config: {
    rpcUrl: string;
    networkId?: number;
    gasOptimizer?: boolean;
  }) {
    this.client = new MonadClient(config.rpcUrl, config.networkId);
    this.batcher = new TransactionBatcher(this.client);
    this.gasOptimizer = new GasOptimizer();
  }

  // Transaction methods
  async sendTransaction(config: TransactionConfig): Promise<TransactionResult> {
    // Optimize gas if enabled
    if (config.optimizeGas) {
      const optimizedConfig = await this.gasOptimizer.optimizeTransaction(config);
      return this.client.sendTransaction(optimizedConfig);
    }
    
    return this.client.sendTransaction(config);
  }

  // Batch transaction methods
  async sendBatch(transactions: TransactionConfig[], config?: BatchConfig): Promise<BatchResult> {
    return this.batcher.sendBatch(transactions, config);
  }

  // Utility methods
  async getGasPrice(): Promise<bigint> {
    return this.client.getGasPrice();
  }

  async estimateGas(config: TransactionConfig): Promise<bigint> {
    return this.client.estimateGas(config);
  }

  // Gas optimization methods
  async optimizeGas(config: TransactionConfig): Promise<TransactionConfig> {
    return this.gasOptimizer.optimizeTransaction(config);
  }

  setGasOptimization(enabled: boolean): void {
    this.gasOptimizer.setEnabled(enabled);
  }

  // Get SDK information
  getVersion(): string {
    return '1.0.0';
  }

  getNetworkInfo(): { chainId: number; rpcUrl: string } {
    return {
      chainId: this.client.getChainId(),
      rpcUrl: this.client.getRpcUrl()
    };
  }
}