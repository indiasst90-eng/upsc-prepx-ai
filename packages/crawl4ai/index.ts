/**
 * Crawl4AI Integration for UPSC PrepX-AI
 * 
 * Fetches current affairs and government schemes from allowed UPSC domains.
 * Based on: https://github.com/unclecode/crawl4ai
 * 
 * ALLOWED DOMAINS (strictly enforced):
 * - visionias.in (Primary - Value Added Notes)
 * - drishtiias.com (Current Affairs, Monthly Compilations)
 * - thehindu.com (Editorial Analysis)
 * - pib.gov.in (Government Press Releases)
 * - forumias.com (Answer Writing, Current Affairs)
 * - iasgyan.in (Subject Notes)
 * - pmfias.com (Geography, Environment)
 * - pwonlyias.com (Test Series, Notes)
 * - byjus.com (NCERT-based content)
 * - insightsonindia.com (Daily Compilations)
 * - *.gov.in (All government websites)
 * - upscpdf.com
 */

import * as cheerio from 'cheerio';

// Allowed domains configuration
export const ALLOWED_DOMAINS: readonly string[] = [
  'visionias.in',
  'drishtiias.com',
  'thehindu.com',
  'pib.gov.in',
  'forumias.com',
  'iasgyan.in',
  'pmfias.com',
  'pwonlyias.com',
  'byjus.com',
  'insightsonindia.com',
  'upscpdf.com',
  // Government domains (*.gov.in)
  'india.gov.in',
  'pmindia.gov.in',
  'mea.gov.in',
  'mha.gov.in',
  'finmin.nic.in',
  'niti.gov.in',
  'moef.gov.in',
  'mohfw.gov.in',
  'dst.gov.in',
];

// Check if URL is from an allowed domain
export function isAllowedDomain(url: string): boolean {
  try {
    const urlObj = new URL(url);
    const hostname = urlObj.hostname.toLowerCase();
    
    // Check exact match
    if (ALLOWED_DOMAINS.includes(hostname)) {
      return true;
    }
    
    // Check for *.gov.in wildcard
    if (hostname.endsWith('.gov.in') || hostname.endsWith('.nic.in')) {
      return true;
    }
    
    // Check subdomain matches
    for (const domain of ALLOWED_DOMAINS) {
      if (hostname.endsWith(`.${domain}`) || hostname === domain) {
        return true;
      }
    }
    
    return false;
  } catch {
    return false;
  }
}

// Content types
export type ContentType = 'current_affairs' | 'government_scheme' | 'editorial' | 'analysis' | 'notes';

// Crawled content structure
export interface CrawledContent {
  url: string;
  title: string;
  content: string;
  contentType: ContentType;
  publishDate?: string;
  source: string;
  topics: string[];
  relatedSchemes?: string[];
  syllabusMapping?: string[];
  extractedAt: string;
}

// Search parameters
export interface SearchParams {
  topic: string;
  contentTypes?: ContentType[];
  dateRange?: {
    from?: string;
    to?: string;
  };
  maxResults?: number;
}

// Domain-specific extractors
interface DomainExtractor {
  extractContent: (html: string, url: string) => Partial<CrawledContent>;
  searchUrl?: (topic: string) => string;
}

const domainExtractors: Record<string, DomainExtractor> = {
  'drishtiias.com': {
    extractContent: (html, url) => {
      const $ = cheerio.load(html);
      return {
        title: $('h1.entry-title, h1.title').first().text().trim() || $('h1').first().text().trim(),
        content: $('.entry-content, .content-area, article').text().trim(),
        contentType: url.includes('daily-updates') ? 'current_affairs' : 'notes',
        publishDate: $('time, .date, .post-date').first().attr('datetime') || $('time, .date, .post-date').first().text().trim(),
        topics: extractTopicsFromText($('.entry-content, article').text()),
      };
    },
    searchUrl: (topic) => `https://www.drishtiias.com/?s=${encodeURIComponent(topic)}`,
  },
  
  'pib.gov.in': {
    extractContent: (html, url) => {
      const $ = cheerio.load(html);
      return {
        title: $('h2.title, h1').first().text().trim(),
        content: $('.content-box, .content, article').text().trim(),
        contentType: 'government_scheme',
        publishDate: $('time, .date').first().text().trim(),
        topics: extractTopicsFromText($('.content').text()),
        relatedSchemes: extractSchemeNames($('.content').text()),
      };
    },
    searchUrl: (topic) => `https://pib.gov.in/AllRelease.aspx?search=${encodeURIComponent(topic)}`,
  },
  
  'thehindu.com': {
    extractContent: (html, url) => {
      const $ = cheerio.load(html);
      return {
        title: $('h1.title, h1').first().text().trim(),
        content: $('article, .article-body, .story-body').text().trim(),
        contentType: url.includes('editorial') || url.includes('opinion') ? 'editorial' : 'current_affairs',
        publishDate: $('time').first().attr('datetime') || $('.publish-time, .date').first().text().trim(),
        topics: extractTopicsFromText($('article').text()),
      };
    },
    searchUrl: (topic) => `https://www.thehindu.com/search/?q=${encodeURIComponent(topic)}`,
  },
  
  'insightsonindia.com': {
    extractContent: (html, url) => {
      const $ = cheerio.load(html);
      return {
        title: $('h1.entry-title, h1').first().text().trim(),
        content: $('.entry-content, article').text().trim(),
        contentType: 'current_affairs',
        publishDate: $('time, .date').first().text().trim(),
        topics: extractTopicsFromText($('.entry-content').text()),
      };
    },
    searchUrl: (topic) => `https://www.insightsonindia.com/?s=${encodeURIComponent(topic)}`,
  },
  
  'visionias.in': {
    extractContent: (html, url) => {
      const $ = cheerio.load(html);
      return {
        title: $('h1, .title').first().text().trim(),
        content: $('.content, article, .post-content').text().trim(),
        contentType: 'notes',
        topics: extractTopicsFromText($('.content, article').text()),
      };
    },
  },
};

// Extract topics from text using keyword matching
function extractTopicsFromText(text: string): string[] {
  const topicKeywords = [
    // Polity
    'constitution', 'parliament', 'judiciary', 'fundamental rights', 'directive principles',
    'president', 'prime minister', 'supreme court', 'high court', 'governor', 'legislature',
    // Economy
    'gdp', 'inflation', 'rbi', 'fiscal policy', 'monetary policy', 'budget', 'taxation',
    'banking', 'finance', 'economic survey', 'niti aayog', 'gst', 'investment',
    // Environment
    'climate change', 'biodiversity', 'pollution', 'conservation', 'wildlife', 'forest',
    'renewable energy', 'sustainable development', 'environment impact', 'carbon',
    // International Relations
    'bilateral relations', 'g20', 'un', 'wto', 'imf', 'world bank', 'brics', 'quad',
    'foreign policy', 'diplomacy', 'trade agreement', 'security council',
    // Science & Tech
    'isro', 'drdo', 'space', 'ai', 'artificial intelligence', 'biotechnology', 'quantum',
    'cyber security', 'digital india', 'technology', 'innovation', 'research',
    // Social Issues
    'education', 'health', 'poverty', 'rural development', 'women empowerment',
    'tribal welfare', 'social justice', 'reservation', 'caste', 'demographic',
    // Security
    'defence', 'terrorism', 'border', 'naxalism', 'cyber crime', 'internal security',
    'armed forces', 'national security', 'intelligence',
  ];
  
  const lowerText = text.toLowerCase();
  return topicKeywords.filter(topic => lowerText.includes(topic));
}

// Extract government scheme names from text
function extractSchemeNames(text: string): string[] {
  const schemePatterns = [
    /(?:PM|Pradhan Mantri)\s+[\w\s]+(?:Yojana|Abhiyan|Mission|Scheme)/gi,
    /(?:National|Rashtriya)\s+[\w\s]+(?:Mission|Abhiyan|Yojana|Scheme)/gi,
    /(?:Swachh|Digital|Make in|Start-?up|Skill|Smart|Atal)\s+[\w\s]+/gi,
    /(?:Jan\s+Dhan|Ujjwala|Mudra|Ayushman|Kisan|Gram)\s*[\w\s]*/gi,
  ];
  
  const schemes: string[] = [];
  for (const pattern of schemePatterns) {
    const matches = text.match(pattern);
    if (matches) {
      schemes.push(...matches.map(m => m.trim()));
    }
  }
  
  return [...new Set(schemes)];
}

// Fetch and parse content from a URL
export async function fetchContent(url: string): Promise<CrawledContent | null> {
  // Validate domain
  if (!isAllowedDomain(url)) {
    throw new Error(`Domain not allowed: ${url}. Only UPSC-approved sources permitted.`);
  }
  
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'UPSC-PrepX-AI/1.0 (Educational Content Crawler)',
        'Accept': 'text/html,application/xhtml+xml',
      },
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: Failed to fetch ${url}`);
    }
    
    const html = await response.text();
    const urlObj = new URL(url);
    const hostname = urlObj.hostname.replace(/^www\./, '');
    
    // Find matching extractor
    let extractor: DomainExtractor | undefined;
    for (const [domain, ext] of Object.entries(domainExtractors)) {
      if (hostname.includes(domain)) {
        extractor = ext;
        break;
      }
    }
    
    // Use generic extractor if no specific one found
    if (!extractor) {
      extractor = {
        extractContent: (html) => {
          const $ = cheerio.load(html);
          return {
            title: $('h1, title').first().text().trim(),
            content: $('article, .content, main, body').text().trim().substring(0, 10000),
            topics: [],
          };
        },
      };
    }
    
    const extracted = extractor.extractContent(html, url);
    
    return {
      url,
      title: extracted.title || 'Untitled',
      content: extracted.content || '',
      contentType: extracted.contentType || 'current_affairs',
      publishDate: extracted.publishDate,
      source: hostname,
      topics: extracted.topics || [],
      relatedSchemes: extracted.relatedSchemes,
      extractedAt: new Date().toISOString(),
    };
    
  } catch (error) {
    console.error(`Failed to fetch ${url}:`, error);
    return null;
  }
}

// Search for content across allowed domains
export async function searchContent(params: SearchParams): Promise<CrawledContent[]> {
  const results: CrawledContent[] = [];
  const maxResults = params.maxResults || 10;
  
  // Build search URLs for each domain with search capability
  const searchUrls: string[] = [];
  for (const [domain, extractor] of Object.entries(domainExtractors)) {
    if (extractor.searchUrl) {
      searchUrls.push(extractor.searchUrl(params.topic));
    }
  }
  
  // Fetch from each search URL (limited to prevent rate limiting)
  for (const searchUrl of searchUrls.slice(0, 5)) {
    if (results.length >= maxResults) break;
    
    try {
      const content = await fetchContent(searchUrl);
      if (content && content.content.length > 100) {
        results.push(content);
      }
    } catch (error) {
      console.warn(`Search failed for ${searchUrl}:`, error);
    }
  }
  
  return results;
}

// Get latest current affairs for a topic
export async function getLatestCurrentAffairs(topic: string, maxItems: number = 5): Promise<CrawledContent[]> {
  // Priority sources for current affairs
  const currentAffairsSources = [
    `https://www.drishtiias.com/?s=${encodeURIComponent(topic)}`,
    `https://www.insightsonindia.com/?s=${encodeURIComponent(topic)}`,
  ];
  
  const results: CrawledContent[] = [];
  
  for (const url of currentAffairsSources) {
    if (results.length >= maxItems) break;
    
    try {
      const content = await fetchContent(url);
      if (content) {
        results.push(content);
      }
    } catch (error) {
      console.warn(`Failed to fetch current affairs from ${url}:`, error);
    }
  }
  
  return results;
}

// Get government schemes related to a topic
export async function getRelatedSchemes(topic: string): Promise<CrawledContent[]> {
  const pibSearchUrl = `https://pib.gov.in/AllRelease.aspx?search=${encodeURIComponent(topic)}`;
  
  try {
    const content = await fetchContent(pibSearchUrl);
    if (content) {
      return [content];
    }
  } catch (error) {
    console.warn('Failed to fetch from PIB:', error);
  }
  
  return [];
}

// Export utility functions
export const utils = {
  isAllowedDomain,
  extractTopicsFromText,
  extractSchemeNames,
  ALLOWED_DOMAINS,
};
