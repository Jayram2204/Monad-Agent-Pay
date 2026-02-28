'use client';

import { createConfig, http } from 'wagmi';
import { mainnet } from 'wagmi/chains';

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
      http: ['https://testnet.monad.dev'],
    },
    public: {
      http: ['https://testnet.monad.dev'],
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
    [monadTestnet.id]: http(),
    [mainnet.id]: http(),
  },
});