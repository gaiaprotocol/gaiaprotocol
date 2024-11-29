import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";
import { Storage } from "npm:@google-cloud/storage";

const storage = new Storage({
  projectId: Deno.env.get("GOOGLE_PROJECT_ID"),
  credentials: {
    client_email: Deno.env.get("GOOGLE_CLIENT_EMAIL"),
    private_key: Deno.env.get("GOOGLE_PRIVATE_KEY")?.replace(/\\n/g, "\n"),
  },
});

const bucket = storage.bucket("gaiaprotocol");

serve(async (req) => {
  const formData = await req.formData();
  const file = formData.get("file");

  if (!(file instanceof File)) {
    throw new Error("Invalid file format");
  }

  const fileName = `${crypto.randomUUID()}.${file.name.split(".").pop()}`;
  const filePath = "material_logos/" + fileName;

  const blob = bucket.file(filePath);
  await blob.save(file.stream() as any, {
    contentType: file.type,
    metadata: { cacheControl: "public, max-age=31536000, immutable" },
  });

  return filePath;
});
