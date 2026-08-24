// Supabase Edge Function: gdrive-upload
// Uploads document binary files directly to a single Google Drive folder via Google Drive API v3

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  corsHeaders,
  decodeBase64Safe,
  extractCredentials,
  getGoogleDriveAccessToken,
} from '../_shared/gdrive_auth.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const { fileName, mimeType, fileBase64, folderName, userId } = body;

    if (!fileName || !fileBase64) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: fileName, fileBase64' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { rootFolderId } = extractCredentials();
    if (!rootFolderId) {
      return new Response(
        JSON.stringify({
          error: 'GDRIVE_FOLDER_ID secret is not configured in Supabase secrets.',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Get OAuth Access Token
    const accessToken = await getGoogleDriveAccessToken();

    // 2. Safely decode base64 file data
    const fileBytesBuffer = decodeBase64Safe(fileBase64);
    const fileBytes = new Uint8Array(fileBytesBuffer);

    const effectiveMimeType = mimeType || 'application/octet-stream';

    // 3. Prepare Multipart Upload to Google Drive API v3
    const boundary = '-------314159265358979323846';
    const delimiter = `\r\n--${boundary}\r\n`;
    const closeDelimiter = `\r\n--${boundary}--`;

    const metadata = {
      name: fileName,
      parents: [rootFolderId],
      mimeType: effectiveMimeType,
      description: `Uploaded by KT Vault for user: ${userId || 'System'}${
        folderName ? ` (Category: ${folderName})` : ''
      }`,
    };

    const metadataPart = `${delimiter}Content-Type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(
      metadata
    )}`;
    const mediaHeaderPart = `${delimiter}Content-Type: ${effectiveMimeType}\r\n\r\n`;

    const encoder = new TextEncoder();
    const part1 = encoder.encode(metadataPart);
    const part2 = encoder.encode(mediaHeaderPart);
    const part4 = encoder.encode(closeDelimiter);

    const bodyBuffer = new Uint8Array(
      part1.length + part2.length + fileBytes.length + part4.length
    );
    bodyBuffer.set(part1, 0);
    bodyBuffer.set(part2, part1.length);
    bodyBuffer.set(fileBytes, part1.length + part2.length);
    bodyBuffer.set(part4, part1.length + part2.length + fileBytes.length);

    const uploadResponse = await fetch(
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true&fields=id,name,mimeType,size,webViewLink,webContentLink,thumbnailLink',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': `multipart/related; boundary=${boundary}`,
          'Content-Length': bodyBuffer.length.toString(),
        },
        body: bodyBuffer,
      }
    );

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text();
      console.error('Google Drive upload error:', errorText);
      return new Response(
        JSON.stringify({ error: `Google Drive API Upload Failed: ${errorText}` }),
        { status: uploadResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const driveFile = await uploadResponse.json();

    // 4. Set permission: Anyone with link can view (enables direct preview & download)
    try {
      await fetch(
        `https://www.googleapis.com/drive/v3/files/${driveFile.id}/permissions?supportsAllDrives=true`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            role: 'reader',
            type: 'anyone',
          }),
        }
      );
    } catch (permErr) {
      console.warn('Non-fatal warning setting file permission:', permErr);
    }

    return new Response(
      JSON.stringify({
        success: true,
        fileId: driveFile.id,
        fileName: driveFile.name,
        mimeType: driveFile.mimeType,
        size: driveFile.size,
        webViewLink: driveFile.webViewLink,
        webContentLink: driveFile.webContentLink,
        thumbnailLink: driveFile.thumbnailLink,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Edge Function Exception (gdrive-upload):', error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
