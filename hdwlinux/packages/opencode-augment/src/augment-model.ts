import { AugmentLanguageModel, AugmentLanguageModelConfig } from '@augmentcode/auggie-sdk';
import type { LanguageModelV2, ProviderV2 } from '@ai-sdk/provider';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

/** Default Augment API URL used when no other URL is configured. */
const DEFAULT_API_URL = 'https://api.augmentcode.com';

/**
 * Logs debug messages when OPENCODE_AUGMENT_PROVIDER_DEBUG environment variable is set.
 */
function log(message: string, extra?: Record<string, unknown>): void {
  if (!process.env['OPENCODE_AUGMENT_PROVIDER_DEBUG']) return;
  const parts = ['[augment-provider]', message];
  if (extra && Object.keys(extra).length > 0) {
    parts.push(JSON.stringify(extra));
  }
  console.debug(parts.join(' '));
}

/**
 * Configuration options for the Augment provider.
 *
 * Credentials are resolved in the following order:
 * 1. Explicit `apiKey` option
 * 2. `AUGMENT_API_KEY` environment variable
 * 3. `~/.augment/session.json` file (created by Augment CLI login)
 */
export interface AugmentProviderOptions {
  /** Augment API key. If not provided, falls back to environment or session file. */
  apiKey?: string;
  /** Augment API URL. Defaults to the URL from session file or standard Augment API. */
  apiUrl?: string;
}

/** Cached config to avoid re-reading session file on every model creation. */
let cachedConfig: AugmentLanguageModelConfig | null = null;

/** Structure of ~/.augment/session.json created by Augment CLI. */
interface AugmentSession {
  accessToken: string;
  tenantURL: string;
}

/**
 * Resolves Augment credentials synchronously.
 *
 * Resolution order:
 * 1. Explicit options (apiKey, apiUrl)
 * 2. Environment variables (AUGMENT_API_KEY, AUGMENT_API_URL)
 * 3. Session file (~/.augment/session.json)
 *
 * @throws Error if no valid credentials can be found
 */
function resolveConfigSync(options: AugmentProviderOptions): AugmentLanguageModelConfig {
  if (options.apiKey) {
    log('Using API key from options');
    return {
      apiKey: options.apiKey,
      apiUrl: options.apiUrl ?? DEFAULT_API_URL,
    };
  }

  const envApiKey = process.env.AUGMENT_API_KEY;
  if (envApiKey) {
    log('Using API key from environment');
    return {
      apiKey: envApiKey,
      apiUrl: process.env.AUGMENT_API_URL ?? DEFAULT_API_URL,
    };
  }

  if (cachedConfig) {
    log('Using cached config');
    return cachedConfig;
  }

  const sessionPath = path.join(os.homedir(), '.augment', 'session.json');
  log('Reading session file', { path: sessionPath });

  try {
    const sessionData = fs.readFileSync(sessionPath, 'utf-8');
    const session: AugmentSession = JSON.parse(sessionData);

    if (!session.accessToken || !session.tenantURL) {
      throw new Error('Session file missing accessToken or tenantURL');
    }

    cachedConfig = {
      apiKey: session.accessToken,
      apiUrl: session.tenantURL,
    };
    log('Loaded credentials from session file');
    return cachedConfig;
  } catch (err) {
    const error = err as NodeJS.ErrnoException;
    const hint = error.code === 'ENOENT'
      ? 'Run "auggie login" or set AUGMENT_API_KEY'
      : error.message;
    throw new Error(`Failed to resolve Augment credentials: ${hint}`);
  }
}

/**
 * Creates an Augment provider for use with OpenCode.
 *
 * @example
 * ```typescript
 * const provider = createAugment();
 * const model = provider.languageModel('claude-sonnet-4');
 * ```
 *
 * @param options - Optional configuration. If not provided, credentials are
 *                  resolved from environment variables or session file.
 * @returns A ProviderV2 implementation for the Vercel AI SDK
 */
export function createAugment(options: AugmentProviderOptions = {}): ProviderV2 {
  log('createAugment called', { options });

  return {
    languageModel(modelId: string): LanguageModelV2 {
      log('Creating language model', { modelId });
      const config = resolveConfigSync(options);
      return new AugmentLanguageModel(modelId, config) as LanguageModelV2;
    },

    textEmbeddingModel(modelId: string) {
      throw new Error(`Augment provider does not support text embeddings: ${modelId}`);
    },

    imageModel(modelId: string) {
      throw new Error(`Augment provider does not support image models: ${modelId}`);
    },
  };
}
