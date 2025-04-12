import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

const IMGBB_API_KEY = Deno.env.get("IMGBB_API_KEY");
const IMGBB_API_URL = "https://api.imgbb.com/1/upload";

serve(async (req) => {
  await extractWalletAddressFromRequest(req);

  const formData = await req.formData();
  const imageFile = formData.get("image");

  if (!(imageFile instanceof File)) throw new Error("Invalid image format");

  const response = await fetch(`${IMGBB_API_URL}?key=${IMGBB_API_KEY}`, {
    method: "POST",
    body: formData,
  });

  const data = await response.json();
  return {
    imageUrl: data.data.url,
    thumbnailUrl: data.data.thumb.url,
  };
});
