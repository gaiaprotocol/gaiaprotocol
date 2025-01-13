import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { insert } from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

serve(async (req, ip) => {
  const walletAddress = extractWalletAddressFromRequest(req);
  const { title, content } = await req.json();

  if (typeof title !== "string" || typeof content !== "string") {
    throw new Error("Invalid input");
  }

  const data = await insert<
    {
      id: string;
      author: string;
      title: string;
      content: string;
      ip_address: string;
    }
  >(
    "persona_posts",
    { author: walletAddress, title, content, ip_address: ip },
    "id",
  );

  return data.id;
});
