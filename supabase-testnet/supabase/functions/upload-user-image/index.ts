import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

const IMGBB_API_KEY = Deno.env.get("IMGBB_API_KEY");
const IMGBB_API_URL = "https://api.imgbb.com/1/upload";

serve(async (req) => {
  await extractWalletAddressFromRequest(req);

  const formData = await req.formData();
  const file = formData.get("file");

  if (!(file instanceof File)) {
    throw new Error("Invalid file format");
  }

  const response = await fetch(IMGBB_API_URL, {
    method: "POST",
    body: new FormData().append("image", file),
    headers: {
      Authorization: `Bearer ${IMGBB_API_KEY}`,
    },
  });

  const data = await response.json();
  console.log(data);
  return data.data.url;
});
