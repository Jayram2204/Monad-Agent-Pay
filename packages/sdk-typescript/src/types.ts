// Transaction types
export enum CallType {
  CALL = 'CALL',
  DELEGATECALL = 'DELEGATECALL',
  BATCH = 'BATCH' // Parallel Transaction Batching
}

export interface TransactionConfig {
  from: string;
  to: string;
  value?: bigint;
  data?: string;
  gasLimit?: bigint;
  gasPrice?: bigint;
  nonce?: number;
  callType?: CallType;
  sessionId?: string; // For session-based transactions
  optimizeGas?: boolean;
  priority?: number; // For batch ordering
}

export interface BatchConfig {
  maxBatchSize?: number;
  gasOptimization?: boolean;
  parallelExecution?: boolean;
  timeout?: number;
}

// Results
export interface TransactionResult {
  hash: string;
  status: 'success' | 'failed';
  gasUsed: bigint;
  gasPrice: bigint;
  blockNumber?: number;
  timestamp: number;
}

export interface BatchResult {
  batchId: string;
  transactions: TransactionResult[];
  totalGasSaved: bigint;
  baseFeeReduction: number; // Percentage
  executionTime: number; // ms
  status: 'success' | 'partial' | 'failed';
}

// Gas optimization
export interface GasEstimate {
  estimatedGas: bigint;
  confidenceInterval: [bigint, bigint];
  optimalGas: bigint;
  savings: bigint;
}

// Network configuration
export interface NetworkConfig {
  chainId: number;
  rpcUrl: string;
  gasPriceOracle?: string;
  blockTime: number;
}

// Session management
export interface SessionConfig {
  sessionId: string;
  spendLimit: bigint;
  duration: number; // seconds
  beneficiary: string;
}

export interface SessionResult {
  sessionId: string;
  isActive: boolean;
  remainingLimit: bigint;
  expiresAt: number;
}