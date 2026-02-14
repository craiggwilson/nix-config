/**
 * Configuration Management for OpenCode Planning Plugins
 */

import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

export interface ConfigSchema {
  [key: string]: unknown;
}

export class ConfigManager {
  private configDir: string;
  private cache: Map<string, ConfigSchema> = new Map();

  constructor(configDir?: string) {
    this.configDir =
      configDir || join(homedir(), ".config", "opencode", "plugins");
  }

  /**
   * Load configuration for a plugin
   */
  load<T extends ConfigSchema>(pluginName: string, defaults?: T): T {
    // Check cache first
    if (this.cache.has(pluginName)) {
      return this.cache.get(pluginName) as T;
    }

    const configPath = join(this.configDir, `${pluginName}.json`);

    let config: T = defaults || ({} as T);

    if (existsSync(configPath)) {
      try {
        const content = readFileSync(configPath, "utf-8");
        const loaded = JSON.parse(content);
        config = { ...config, ...loaded };
      } catch (error) {
        console.warn(`Failed to load config from ${configPath}:`, error);
      }
    }

    this.cache.set(pluginName, config);
    return config;
  }

  /**
   * Save configuration for a plugin
   */
  save(pluginName: string, config: ConfigSchema): void {
    const configPath = join(this.configDir, `${pluginName}.json`);

    try {
      writeFileSync(configPath, JSON.stringify(config, null, 2), "utf-8");
      this.cache.set(pluginName, config);
    } catch (error) {
      throw new Error(`Failed to save config to ${configPath}: ${error}`);
    }
  }

  /**
   * Merge global and per-repo configuration
   */
  mergeWithRepoConfig<T extends ConfigSchema>(
    pluginName: string,
    repoConfigPath: string,
    defaults?: T
  ): T {
    // Load global config
    const globalConfig = this.load(pluginName, defaults);

    // Load repo config if it exists
    let repoConfig: Partial<T> = {};
    if (existsSync(repoConfigPath)) {
      try {
        const content = readFileSync(repoConfigPath, "utf-8");
        repoConfig = JSON.parse(content);
      } catch (error) {
        console.warn(`Failed to load repo config from ${repoConfigPath}:`, error);
      }
    }

    // Merge: repo config overrides global config
    return { ...globalConfig, ...repoConfig } as T;
  }

  /**
   * Clear cache
   */
  clearCache(): void {
    this.cache.clear();
  }
}
