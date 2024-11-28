import {
  Abi,
  createPublicClient,
  decodeEventLog,
  http,
} from "https://esm.sh/viem@2.21.47";
import { mainnet } from "https://esm.sh/viem@2.21.47/chains";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { getChainById } from "https://raw.githubusercontent.com/yjgaia/wallet-utils/refs/heads/main/deno/mod.ts";
import ClanEmblemsArtifact from "../_shared/artifacts/ClanEmblems.json" with {
  type: "json",
};
import MaterialFactoryArtifact from "../_shared/artifacts/MaterialFactory.json" with {
  type: "json",
};
import PersonaFragmentsArtifact from "../_shared/artifacts/PersonaFragments.json" with {
  type: "json",
};
import TopicSharesArtifact from "../_shared/artifacts/TopicShares.json" with {
  type: "json",
};

const INFURA_API_KEY = Deno.env.get("INFURA_API_KEY")!;

interface ContractInfo {
  address: `0x${string}`;
  deploymentBlock: number;
  abi: Abi;
}

const contracts: Record<string, ContractInfo> = {
  PersonaFragments: {
    address: Deno.env.get(
      "PERSONA_FRAGMENTS_CONTRACT_ADDRESS",
    )! as `0x${string}`,
    deploymentBlock: parseInt(
      Deno.env.get("PERSONA_FRAGMENTS_DEPLOYMENT_BLOCK")!,
    ),
    abi: PersonaFragmentsArtifact.abi as Abi,
  },
  ClanEmblems: {
    address: Deno.env.get("CLAN_EMBLEMS_CONTRACT_ADDRESS")! as `0x${string}`,
    deploymentBlock: parseInt(Deno.env.get("CLAN_EMBLEMS_DEPLOYMENT_BLOCK")!),
    abi: ClanEmblemsArtifact.abi as Abi,
  },
  TopicShares: {
    address: Deno.env.get("TOPIC_SHARES_CONTRACT_ADDRESS")! as `0x${string}`,
    deploymentBlock: parseInt(Deno.env.get("TOPIC_SHARES_DEPLOYMENT_BLOCK")!),
    abi: TopicSharesArtifact.abi as Abi,
  },
  MaterialFactory: {
    address: Deno.env.get(
      "MATERIAL_FACTORY_CONTRACT_ADDRESS",
    )! as `0x${string}`,
    deploymentBlock: parseInt(
      Deno.env.get("MATERIAL_FACTORY_DEPLOYMENT_BLOCK")!,
    ),
    abi: MaterialFactoryArtifact.abi as Abi,
  },
};

interface EventEntity {
  chain_id: number;
  contract_address: `0x${string}`;
  block_number: number;
  log_index: number;
  transaction_hash: string;
  name: string;
  args: any;
}

interface RequestBody {
  chainId: number;
  contract: string;
  blockPeriod?: number;
}

const UPGRADE_RELATED_TOPICS = new Set<`0x${string}`>([
  "0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b", // Upgraded(address)
  "0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f", // AdminChanged(address,address)
]);

serve(async (req) => {
  let { chainId, contract, blockPeriod } = await req.json() as RequestBody;
  if (!chainId || !contract) {
    throw new Error("Missing 'chainId' or 'contract' in the request body.");
  }

  const contractInfo = contracts[contract];
  if (!contractInfo) throw new Error(`Invalid contract: ${contract}`);

  if (!blockPeriod || isNaN(blockPeriod)) {
    const defaultBlockPeriods: Record<number, number> = {
      8453: 500, // Base mainnet
      84532: 500, // Base testnet
      42161: 2500, // Arbitrum One
      421614: 2500, // Arbitrum testnet
    };
    blockPeriod = defaultBlockPeriods[chainId] ?? 750;
  }

  const chain = getChainById(chainId);
  if (!chain) throw new Error(`Unsupported chainId: ${chainId}`);

  const client = createPublicClient({
    chain,
    transport: chain === mainnet
      ? http(`https://mainnet.infura.io/v3/${INFURA_API_KEY}`)
      : http(),
  });

  const syncStatus = await safeFetchSingle<
    { last_synced_block_number: number }
  >("contract_event_sync_status", (b) =>
    b.select("last_synced_block_number")
      .eq("chain_id", chainId)
      .eq("contract_address", contractInfo.address));

  const currentBlock = await client.getBlockNumber();
  const toBlock = Math.min(
    (syncStatus
      ? syncStatus.last_synced_block_number
      : contractInfo.deploymentBlock) + blockPeriod,
    Number(currentBlock),
  );
  const fromBlock = toBlock - blockPeriod * 2;

  const logs = await client.getLogs({
    address: contractInfo.address,
    fromBlock: BigInt(fromBlock),
    toBlock: BigInt(toBlock),
  });

  const events: EventEntity[] = [];
  for (const log of logs) {
    const { blockNumber, transactionHash, logIndex, topics, data } = log;

    // Skip the first topic if it's the contract's upgrade event
    if (topics[0] && UPGRADE_RELATED_TOPICS.has(topics[0])) {
      continue;
    }

    const decodedLog = decodeEventLog({
      abi: contractInfo.abi,
      data,
      topics,
    });

    events.push({
      chain_id: chainId,
      contract_address: contractInfo.address,
      block_number: Number(blockNumber),
      log_index: Number(logIndex),
      transaction_hash: transactionHash,
      name: decodedLog.eventName as any,
      args: Object.fromEntries(
        Object.entries(decodedLog.args as any).map(([key, value]) => [
          key,
          typeof value === "bigint" ? value.toString() : value,
        ]),
      ),
    });
  }

  await safeStore("contract_events", (b) => b.upsert(events));
  await safeStore("contract_event_sync_status", (b) =>
    b.upsert({
      chain_id: chainId,
      contract_address: contractInfo.address,
      last_synced_block_number: toBlock,
    }));
});