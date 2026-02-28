import { ethers } from 'ethers';
import { 
  TransactionConfig, 
  TransactionResult, 
  NetworkConfig,
  CallType
} from './types';

export class MonadClient {
  private provider: ethers.JsonRpcProvider;
  private network: NetworkConfig;
  private signer: ethers.Wallet | null = null;

  constructor(rpcUrl: string, networkId?: number) {
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.network = {
      chainId: networkId || 10143, // Default Monad testnet
      rpcUrl,
      blockTime: 1000 // 1 second block time
    };
  }

  // Connection methods
  async connect(signer: ethers.Wallet): Promise<void> {
    this.signer = signer;
  }

  isConnected(): boolean {
    return this.signer !== null;
  }

  // Transaction methods
  async sendTransaction(config: TransactionConfig): Promise<TransactionResult> {
    if (!this.signer) {
      throw new Error('No signer connected');
    }

    try {
      // Prepare transaction
      const tx = {
        to: config.to,
        value: config.value || 0n,
        data: config.data || '0x',
        gasLimit: config.gasLimit,
        gasPrice: config.gasPrice,
        nonce: config.nonce
      };

      // Handle different call types
      let transactionResponse: ethers.TransactionResponse;
      
      switch (config.callType) {
        case CallType.BATCH:
          // For batch transactions, use specialized handling
          transactionResponse = await this.sendBatchTransaction(config);
          break;
        case CallType.DELEGATECALL:
          // For delegate calls, modify the transaction
          transactionResponse = await this.sendDelegateCall(config);
          break;
        default:
          // Standard call
          transactionResponse = await this.signer.sendTransaction(tx);
      }

      // Wait for confirmation
      const receipt = await transactionResponse.wait();
      
      return {
        hash: transactionResponse.hash,
        status: receipt?.status === 1 ? 'success' : 'failed',
        gasUsed: receipt?.gasUsed || 0n,
        gasPrice: transactionResponse.gasPrice || 0n,
        blockNumber: receipt?.blockNumber,
        timestamp: Date.now()
      };

    } catch (error) {
      throw new Error(`Transaction failed: ${error}`);
    }
  }

  private async sendBatchTransaction(config: TransactionConfig): Promise<ethers.TransactionResponse> {
    if (!this.signer) {
      throw new Error('No signer connected');
    }

    // Batch transaction logic - this would interact with Monad's batch endpoint
    const batchTx = {
      ...config,
      callType: CallType.BATCH
    };

    // In a real implementation, this would call Monad's batch RPC endpoint
    // For now, we'll simulate it as a regular transaction
    const tx = {
      to: config.to,
      value: config.value || 0n,
      data: config.data || '0x',
      gasLimit: config.gasLimit,
      gasPrice: config.gasPrice
    };

    return this.signer.sendTransaction(tx);
  }

  private async sendDelegateCall(config: TransactionConfig): Promise<ethers.TransactionResponse> {
    if (!this.signer) {
      throw new Error('No signer connected');
    }

    // Modify transaction for delegate call
    // This would typically involve changing the 'to' address and data
    const delegateTx = {
      to: config.to,
      value: 0n, // Delegate calls typically don't transfer value
      data: config.data || '0x',
      gasLimit: config.gasLimit,
      gasPrice: config.gasPrice
    };

    return this.signer.sendTransaction(delegateTx);
  }

  // Gas methods
  async getGasPrice(): Promise<bigint> {
    try {
      const feeData = await this.provider.getFeeData();
      return feeData.gasPrice || 1000000000n; // Default 1 Gwei
    } catch (error) {
      // Fallback to default gas price
      return 1000000000n; // 1 Gwei
    }
  }

  async estimateGas(config: TransactionConfig): Promise<bigint> {
    try {
      const tx = {
        to: config.to,
        value: config.value || 0n,
        data: config.data || '0x',
        from: config.from
      };

      const estimated = await this.provider.estimateGas(tx);
      
      // Add 20% buffer for safety
      return (estimated * 120n) / 100n;
    } catch (error) {
      // Return default estimate for simple transfers
      if (!config.data || config.data === '0x') {
        return 21000n;
      }
      // For complex transactions, return higher estimate
      return 100000n;
    }
  }

  // Network methods
  async getChainId(): Promise<number> {
    const network = await this.provider.getNetwork();
    return Number(network.chainId);
  }

  getRpcUrl(): string {
    return this.network.rpcUrl;
  }

  getNetworkInfo(): NetworkConfig {
    return { ...this.network };
  }

  // Batch methods
  async sendBatch(transactions: TransactionConfig[]): Promise<TransactionResult[]> {
    const results: TransactionResult[] = [];
    
    // Process transactions in parallel for maximum efficiency
    const promises = transactions.map(async (tx) => {
      try {
        const result = await this.sendTransaction(tx);
        return result;
      } catch (error) {
        return {
          hash: `failed_${Date.now()}`,
          status: 'failed',
          gasUsed: 0n,
          gasPrice: 0n,
          timestamp: Date.now()
        } as TransactionResult;
      }
    });

    const batchResults = await Promise.all(promises);
    return batchResults.filter(result => result.status === 'success');
  }

  // Utility methods
  async getBalance(address: string): Promise<bigint> {
    return this.provider.getBalance(address);
  }

  async getTransactionCount(address: string): Promise<number> {
    return this.provider.getTransactionCount(address);
  }

  async waitForTransaction(hash: string, confirmations?: number): Promise<ethers.TransactionReceipt | null> {
    return this.provider.waitForTransaction(hash, confirmations);
  }
}