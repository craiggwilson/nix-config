/**
 * Configuration Management for OpenCode Planning Plugins
 */
export interface ConfigSchema {
    [key: string]: unknown;
}
export declare class ConfigManager {
    private configDir;
    private cache;
    constructor(configDir?: string);
    /**
     * Load configuration for a plugin
     */
    load<T extends ConfigSchema>(pluginName: string, defaults?: T): T;
    /**
     * Save configuration for a plugin
     */
    save(pluginName: string, config: ConfigSchema): void;
    /**
     * Merge global and per-repo configuration
     */
    mergeWithRepoConfig<T extends ConfigSchema>(pluginName: string, repoConfigPath: string, defaults?: T): T;
    /**
     * Clear cache
     */
    clearCache(): void;
}
//# sourceMappingURL=config.d.ts.map