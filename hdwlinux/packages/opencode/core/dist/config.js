/**
 * Configuration Management for OpenCode Planning Plugins
 */
import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";
export class ConfigManager {
    constructor(configDir) {
        this.cache = new Map();
        this.configDir =
            configDir || join(homedir(), ".config", "opencode", "plugins");
    }
    /**
     * Load configuration for a plugin
     */
    load(pluginName, defaults) {
        // Check cache first
        if (this.cache.has(pluginName)) {
            return this.cache.get(pluginName);
        }
        const configPath = join(this.configDir, `${pluginName}.json`);
        let config = defaults || {};
        if (existsSync(configPath)) {
            try {
                const content = readFileSync(configPath, "utf-8");
                const loaded = JSON.parse(content);
                config = { ...config, ...loaded };
            }
            catch (error) {
                console.warn(`Failed to load config from ${configPath}:`, error);
            }
        }
        this.cache.set(pluginName, config);
        return config;
    }
    /**
     * Save configuration for a plugin
     */
    save(pluginName, config) {
        const configPath = join(this.configDir, `${pluginName}.json`);
        try {
            writeFileSync(configPath, JSON.stringify(config, null, 2), "utf-8");
            this.cache.set(pluginName, config);
        }
        catch (error) {
            throw new Error(`Failed to save config to ${configPath}: ${error}`);
        }
    }
    /**
     * Merge global and per-repo configuration
     */
    mergeWithRepoConfig(pluginName, repoConfigPath, defaults) {
        // Load global config
        const globalConfig = this.load(pluginName, defaults);
        // Load repo config if it exists
        let repoConfig = {};
        if (existsSync(repoConfigPath)) {
            try {
                const content = readFileSync(repoConfigPath, "utf-8");
                repoConfig = JSON.parse(content);
            }
            catch (error) {
                console.warn(`Failed to load repo config from ${repoConfigPath}:`, error);
            }
        }
        // Merge: repo config overrides global config
        return { ...globalConfig, ...repoConfig };
    }
    /**
     * Clear cache
     */
    clearCache() {
        this.cache.clear();
    }
}
//# sourceMappingURL=config.js.map