// Supabase Edge Function: gdrive-proxy
// Securely streams or downloads files directly from Google Drive without exposing tokens

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsHeaders, getGoogleDriveAccessToken } from '../_shared/gdrive_auth.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const fileId = url.searchParams.get('fileId');
    const isDownload = url.searchParams.get('download') === 'true';

    if (!fileId) {
      return new Response(JSON.stringify({ error: 'fileId query parameter is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const accessToken = await getGoogleDriveAccessToken();

    // 1. Fetch File Metadata
    const metaResponse = await fetch(
      `https://www.googleapis.com/drive/v3/files/${fileId}?supportsAllDrives=true&fields=id,name,mimeType,size`,
      {
        headers: { Authorization: `Bearer ${accessToken}` },
      }
    );

    if (!metaResponse.ok) {
      const err = await metaResponse.text();
      return new Response(JSON.stringify({ error: `File not found on Google Drive: ${err}` }), {
        status: metaResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const metadata = await metaResponse.json();

    // 2. Fetch File Binary Stream (alt=media)
    const mediaResponse = await fetch(
      `https://www.googleapis.com/drive/v3/files/${fileId}?alt=media&supportsAllDrives=true`,
      {
        headers: { Authorization: `Bearer ${accessToken}` },
      }
    );

    if (!mediaResponse.ok || !mediaResponse.body) {
      const err = await mediaResponse.text();
      return new Response(JSON.stringify({ error: `Failed to download file media: ${err}` }), {
        status: mediaResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const disposition = isDownload ? 'attachment' : 'inline';

    return new Response(mediaResponse.body, {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': metadata.mimeType || 'application/octet-stream',
        'Content-Disposition': `${disposition}; filename="${metadata.name || 'document'}"`,
        'Cache-Control': 'public, max-age=3600',
      },
    });
  } catch (error) {
    console.error('Edge Function Exception (gdrive-proxy):', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
