import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // Enable ES modules
  experimental: {
    // Modern features
  },
  // Environment variables
  env: {
    NEXT_PUBLIC_MONAD_RPC: process.env.NEXT_PUBLIC_MONAD_RPC || "https://testnet-rpc.monad.xyz",
    NEXT_PUBLIC_CHAIN_ID: process.env.NEXT_PUBLIC_CHAIN_ID || "10143",
  },
};

export default nextConfig;
