import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { insert } from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

serve(async (req, ip) => {
  const walletAddress = await extractWalletAddressFromRequest(req);
  const { title, content } = await req.json();

  if (typeof title !== "string" || typeof content !== "string") {
    throw new Error("Invalid input");
  }

  const data = await insert<
    {
      persona_owner: string;
      id: string;
      title: string;
      content: string;
      ip_address: string;
    }
  >(
    "persona_posts",
    { persona_owner: walletAddress, title, content, ip_address: ip },
    "id",
  );

  return data.id;
});
