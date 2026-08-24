// Shared Google Drive Auth for Supabase Edge Functions

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, DELETE',
};

export function decodeBase64Safe(input: string): Uint8Array {
  let base64 = input.replace(/^data:.*?;base64,/, '').trim();
  base64 = base64.replace(/-/g, '+').replace(/_/g, '/');
  base64 = base64.replace(/[^A-Za-z0-9+/=]/g, '');

  while (base64.length % 4 !== 0) {
    base64 += '=';
  }

  const binaryString = atob(base64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer.slice(0, len) as ArrayBuffer;
}

function cleanEnv(val?: string | null): string {
  if (!val) return '';
  return val.trim().replace(/^["']|["']$/g, '').replace(/\\n/g, '\n').trim();
}

export function extractCredentials(): {
  clientEmail: string;
  privateKeyPem: string;
  rootFolderId: string;
  clientId: string;
  clientSecret: string;
  refreshToken: string;
} {
  const clientEmail = cleanEnv(
    Deno.env.get('GDRIVE_SERVICE_ACCOUNT_EMAIL') ||
    Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL') ||
    Deno.env.get('SERVICE_ACCOUNT_EMAIL')
  );

  let privateKeyRaw = cleanEnv(
    Deno.env.get('GDRIVE_PRIVATE_KEY') ||
    Deno.env.get('GOOGLE_PRIVATE_KEY') ||
    Deno.env.get('GDRIVE_SERVICE_ACCOUNT_KEY') ||
    Deno.env.get('PRIVATE_KEY')
  );

  const rootFolderId = cleanEnv(
    Deno.env.get('GDRIVE_FOLDER_ID') ||
    Deno.env.get('GOOGLE_FOLDER_ID') ||
    Deno.env.get('FOLDER_ID')
  );

  const clientId = cleanEnv(
    Deno.env.get('GDRIVE_CLIENT_ID') ||
    Deno.env.get('GOOGLE_CLIENT_ID') ||
    Deno.env.get('CLIENT_ID')
  );

  const clientSecret = cleanEnv(
    Deno.env.get('GDRIVE_CLIENT_SECRET') ||
    Deno.env.get('GOOGLE_CLIENT_SECRET') ||
    Deno.env.get('CLIENT_SECRET')
  );

  const refreshToken = cleanEnv(
    Deno.env.get('GDRIVE_REFRESH_TOKEN') ||
    Deno.env.get('GOOGLE_REFRESH_TOKEN') ||
    Deno.env.get('REFRESH_TOKEN')
  );

  // If JSON pasted into privateKey
  if (privateKeyRaw.startsWith('{')) {
    try {
      const parsed = JSON.parse(privateKeyRaw);
      if (parsed.private_key) privateKeyRaw = parsed.private_key;
    } catch (_) {
      // not JSON
    }
  }

  return {
    clientEmail,
    privateKeyPem: privateKeyRaw,
    rootFolderId,
    clientId,
    clientSecret,
    refreshToken,
  };
}

function pemToPkcs8(pem: string): ArrayBuffer {
  let clean = pem.replace(/\\n/g, '\n');
  clean = clean
    .replace(/-----BEGIN[ A-Z0-9_-]+-----/g, '')
    .replace(/-----END[ A-Z0-9_-]+-----/g, '');
  clean = clean.replace(/[^A-Za-z0-9+/=]/g, '');

  while (clean.length % 4 !== 0) {
    clean += '=';
  }

  const binaryString = atob(clean);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer.slice(0, len) as ArrayBuffer;
}

export async function getGoogleDriveAccessToken(): Promise<string> {
  const creds = extractCredentials();

  // Mode 1: OAuth2 Refresh Token Flow
  if (creds.refreshToken || creds.clientId || creds.clientSecret) {
    if (!creds.clientId || !creds.clientSecret || !creds.refreshToken) {
      throw new Error(
        `OAuth credentials incomplete: clientId=${Boolean(creds.clientId)}, clientSecret=${Boolean(
          creds.clientSecret
        )}, refreshToken=${Boolean(creds.refreshToken)}. Please ensure all 3 secrets are set.`
      );
    }

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: creds.clientId,
        client_secret: creds.clientSecret,
        refresh_token: creds.refreshToken,
        grant_type: 'refresh_token',
      }).toString(),
    });

    const tokenData = await tokenRes.json();
    if (!tokenRes.ok || !tokenData.access_token) {
      console.error('Google OAuth token endpoint response error:', tokenData);
      const errorMsg = tokenData.error_description || tokenData.error || JSON.stringify(tokenData);
      throw new Error(
        `Google OAuth Refresh Error: ${errorMsg}. (Check that GDRIVE_CLIENT_ID and GDRIVE_CLIENT_SECRET in Supabase match the OAuth credentials used to generate GDRIVE_REFRESH_TOKEN).`
      );
    }
    return tokenData.access_token;
  }

  // Mode 2: Service Account Flow
  if (!creds.clientEmail || !creds.privateKeyPem) {
    throw new Error(
      'Missing Google Drive credentials. Please provide (GDRIVE_CLIENT_ID + GDRIVE_CLIENT_SECRET + GDRIVE_REFRESH_TOKEN) or (GDRIVE_SERVICE_ACCOUNT_EMAIL + GDRIVE_PRIVATE_KEY).'
    );
  }

  const header = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: creds.clientEmail,
    scope: 'https://www.googleapis.com/auth/drive',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');

  const unsignedToken = `${enc(header)}.${enc(payload)}`;

  const binaryKey = pemToPkcs8(creds.privateKeyPem);
  const key = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsignedToken)
  );

  const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  const jwt = `${unsignedToken}.${signatureBase64}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  if (!tokenRes.ok || !tokenData.access_token) {
    throw new Error(
      `Google Service Account Auth Error: ${
        tokenData.error_description || tokenData.error || JSON.stringify(tokenData)
      }`
    );
  }

  return tokenData.access_token;
}
