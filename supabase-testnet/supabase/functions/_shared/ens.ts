import { createPublicClient, http } from "https://esm.sh/viem@2.21.47";
import { mainnet } from "https://esm.sh/viem@2.21.47/chains";

const INFURA_API_KEY = Deno.env.get("INFURA_API_KEY")!;

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http(`https://mainnet.infura.io/v3/${INFURA_API_KEY}`),
});

export async function getEnsName(
  walletAddress: `0x${string}`,
): Promise<string> {
  return await publicClient.getEnsName({ address: walletAddress }) ?? "";
}
