'use client';

import { useState, useEffect } from 'react';
import { usePublicClient } from 'wagmi';

export function NetworkStats() {
  const [blockTime, setBlockTime] = useState(400);
  const [settlementTime, setSettlementTime] = useState(800);
  const [isConnected, setIsConnected] = useState(false);
  const [chainId, setChainId] = useState('10143');
  const publicClient = usePublicClient();

  useEffect(() => {
    const updateNetworkStats = async () => {
      try {
        if (publicClient) {
          // Try to get the actual block number to verify connection
          const blockNumber = await publicClient.getBlockNumber();
          setIsConnected(!!blockNumber);
          
          // Monad testnet has ~400ms block time
          setBlockTime(400);
          // Settlement is 2x block time
          setSettlementTime(800);
          
          // Get chain ID
          const id = await publicClient.getChainId();
          setChainId(id.toString());
        }
      } catch (error) {
        console.error('Failed to fetch network stats:', error);
        setIsConnected(false);
      }
    };

    updateNetworkStats();

    // Update periodically
    const interval = setInterval(updateNetworkStats, 10000);
    return () => clearInterval(interval);
  }, [publicClient]);

  return (
    <div className="flex items-center gap-4 text-sm">
      <div className="flex items-center gap-2">
        <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-400' : 'bg-red-400'}`}></div>
        <span className={isConnected ? 'text-green-400' : 'text-red-400'}>
          {isConnected ? 'CONNECTED' : 'DISCONNECTED'}
        </span>
      </div>
      
      <div className="flex items-center gap-2">
        <span className="text-slate-400">BLOCK:</span>
        <span className="text-neon-pink font-mono">{blockTime}ms</span>
      </div>
      
      <div className="flex items-center gap-2">
        <span className="text-slate-400">SETTLE:</span>
        <span className="text-neon-pink font-mono">{settlementTime}ms</span>
      </div>
      
      <div className="px-2 py-1 bg-monad-purple/20 text-monad-purple border border-monad-purple rounded text-xs">
        MONAD (Chain {chainId})
      </div>
    </div>
  );
}