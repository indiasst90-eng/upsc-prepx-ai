/**
 * Certificate Generator Pipe
 *
 * Generates and manages certificates for achievements:
 * - Course completions
 * - Milestone achievements
 * - Streak accomplishments
 * - Rank achievements
 * - Shareable certificate URLs with verification
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface CertificateRequest {
  action?: 'generate' | 'list' | 'verify' | 'download';
  template_id?: string;
  certificate_id?: string;
  verification_code?: string;
  achievement?: string;
  details?: {
    score?: number;
    date?: string;
    duration?: string;
    topic?: string;
  };
}

interface Certificate {
  id: string;
  certificate_number: string;
  title: string;
  description: string;
  recipient_name: string;
  achievement: string;
  details_json: any;
  certificate_url: string;
  verification_code: string;
  issued_at: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST' && req.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 });
  }

  const startTime = Date.now();
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    const authHeader = req.headers.get('Authorization');

    // GET requests
    if (req.method === 'GET') {
      const url = new URL(req.url);
      const action = url.searchParams.get('action');
      const verificationCode = url.searchParams.get('verification_code');

      if (action === 'verify' && verificationCode) {
        return await verifyCertificate(supabaseAdmin, verificationCode);
      }

      if (action === 'list') {
        if (!authHeader) {
          return new Response(JSON.stringify({ error: 'Unauthorized' }), {
            status: 401,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const supabase = createClient(
          Deno.env.get('SUPABASE_URL')!,
          authHeader.replace('Bearer ', '')
        );
        return await listUserCertificates(supabase, authHeader);
      }
    }

    // POST requests
    const body = await req.json() as CertificateRequest;
    const { action, template_id, achievement, details, certificate_id, verification_code } = body;

    // Generate certificate
    if (action === 'generate') {
      if (!authHeader) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        authHeader.replace('Bearer ', '')
      );
      const { data: { user } } = await supabase.auth.getUser();

      if (!user) {
        return new Response(JSON.stringify({ error: 'User not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return await generateCertificate(
        supabaseAdmin,
        user.id,
        template_id,
        achievement || 'Achievement',
        details,
        startTime
      );
    }

    // Download certificate
    if (action === 'download' && certificate_id) {
      return await downloadCertificate(supabaseAdmin, certificate_id);
    }

    return new Response(JSON.stringify({ error: 'Invalid action' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: (error as Error).message,
      processing_time_seconds: (Date.now() - startTime) / 1000,
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

/**
 * Generate a new certificate
 */
async function generateCertificate(
  supabaseAdmin: any,
  userId: string,
  templateId: string | undefined,
  achievement: string,
  details: any,
  startTime: number
) {
  // Get user profile
  const { data: profile, error: profileError } = await supabaseAdmin
    .from('user_profiles')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (profileError && profileError.code !== 'PGRST116') {
    throw profileError;
  }

  // Get template
  let template = null;
  if (templateId) {
    const { data: templateData } = await supabaseAdmin
      .from('certificate_templates')
      .select('*')
      .eq('id', templateId)
      .single();

    template = templateData;
  } else {
    // Use default template based on achievement type
    const { data: defaultTemplate } = await supabaseAdmin
      .from('certificate_templates')
      .select('*')
      .eq('is_active', true)
      .limit(1)
      .single();

    template = defaultTemplate;
  }

  // Generate certificate number and verification code
  const certificateNumber = await generateCertificateNumber(supabaseAdmin);
  const verificationCode = generateVerificationCode();

  // Get user name
  const recipientName = profile?.full_name || 'UPSC PrepX User';

  // Create certificate record
  const certificateData = {
    user_id: userId,
    template_id: template?.id || null,
    certificate_number: certificateNumber,
    title: `${achievement} Certificate`,
    description: `Certificate of ${achievement}`,
    recipient_name: recipientName,
    achievement,
    details_json: details || {},
    verification_code: verificationCode,
    issued_at: new Date().toISOString(),
  };

  const { data: certificate, error } = await supabaseAdmin
    .from('certificates')
    .insert(certificateData)
    .select()
    .single();

  if (error) throw error;

  // Generate certificate URL (in production, would generate actual PDF/image)
  const certificateUrl = await generateCertificateImage(certificate, template, profile);

  // Update certificate with URL
  await supabaseAdmin
    .from('certificates')
    .update({ certificate_url: certificateUrl })
    .eq('id', certificate.id);

  return new Response(JSON.stringify({
    success: true,
    data: {
      ...certificate,
      certificate_url: certificateUrl,
      verification_url: `${Deno.env.get('APP_URL') || 'https://upsc.prepx.in'}/verify/${verificationCode}`,
    },
    processing_time_seconds: (Date.now() - startTime) / 1000,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Generate unique certificate number
 */
async function generateCertificateNumber(supabaseAdmin: any): Promise<string> {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();

  const number = `CERT-${year}${month}${day}-${random}`;

  // Ensure uniqueness
  const { data: existing } = await supabaseAdmin
    .from('certificates')
    .select('id')
    .eq('certificate_number', number)
    .single();

  if (existing) {
    return generateCertificateNumber(supabaseAdmin);
  }

  return number;
}

/**
 * Generate verification code
 */
function generateVerificationCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 12; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
    if (i === 3 || i === 7) code += '-';
  }
  return code;
}

/**
 * Generate certificate image (placeholder - would use PDF library in production)
 */
async function generateCertificateImage(
  certificate: any,
  template: any,
  profile: any
): Promise<string> {
  // In production, would use a PDF generation library like PDFKit or puppeteer
  // For now, return a placeholder URL
  return `https://storage.googleapis.com/certificates/${certificate.id}.png`;
}

/**
 * List user certificates
 */
async function listUserCertificates(supabase: any, authHeader: string) {
  const { data: { user } } = await supabase.auth.getUser();

  const { data: certificates, error } = await supabase
    .from('certificates')
    .select('*')
    .eq('user_id', user?.id)
    .order('issued_at', { ascending: false });

  if (error) throw error;

  return new Response(JSON.stringify({
    success: true,
    data: certificates,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Verify certificate by code
 */
async function verifyCertificate(supabaseAdmin: any, verificationCode: string) {
  const { data: certificate, error } = await supabaseAdmin
    .from('certificates')
    .select('*, certificate_templates(*)')
    .eq('verification_code', verificationCode)
    .single();

  if (error || !certificate) {
    return new Response(JSON.stringify({
      success: false,
      error: 'Certificate not found',
    }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({
    success: true,
    data: {
      is_valid: true,
      certificate_number: certificate.certificate_number,
      recipient_name: certificate.recipient_name,
      achievement: certificate.achievement,
      issued_at: certificate.issued_at,
      template: certificate.certificate_templates?.name,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Get certificate download URL
 */
async function downloadCertificate(supabaseAdmin: any, certificateId: string) {
  const { data: certificate, error } = await supabaseAdmin
    .from('certificates')
    .select('*')
    .eq('id', certificateId)
    .single();

  if (error || !certificate) {
    return new Response(JSON.stringify({ error: 'Certificate not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // In production, would return signed URL for PDF download
  return new Response(JSON.stringify({
    success: true,
    data: {
      download_url: certificate.certificate_url,
      certificate_number: certificate.certificate_number,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
