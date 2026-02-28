'use client';

import { createConfig, http } from 'wagmi';
import { mainnet } from 'wagmi/chains';

// Get RPC URL from environment or use default
const getRpcUrl = (): string => {
  if (typeof window !== 'undefined' && (window as any).__ENV__?.NEXT_PUBLIC_MONAD_RPC) {
    return (window as any).__ENV__.NEXT_PUBLIC_MONAD_RPC;
  }
  return process.env.NEXT_PUBLIC_MONAD_RPC || 'https://testnet-rpc.monad.xyz';
};

// Monad Testnet configuration
export const monadTestnet = {
  id: 10143,
  name: 'Monad Testnet',
  network: 'monad-testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'MON',
    symbol: 'MON',
  },
  rpcUrls: {
    default: {
      http: [getRpcUrl()],
    },
    public: {
      http: [getRpcUrl()],
    },
  },
  blockExplorers: {
    default: {
      name: 'Monad Explorer',
      url: 'https://testnet.explorer.monad.dev',
    },
  },
  testnet: true,
};

export const config = createConfig({
  chains: [monadTestnet, mainnet],
  transports: {
    [monadTestnet.id]: http(getRpcUrl()),
    [mainnet.id]: http(),
  },
});