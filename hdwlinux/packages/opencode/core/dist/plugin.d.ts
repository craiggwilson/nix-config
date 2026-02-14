/**
 * OpenCode Plugin Interface
 *
 * Defines the core plugin interface for the planning and execution suite.
 */
import type { Plugin } from "@opencode-ai/plugin";
/**
 * Context available to all plugins
 */
export interface PluginContext {
    project: {
        name: string;
        path: string;
    };
    directory: string;
    worktree: string;
    client: any;
    $: any;
}
/**
 * Command definition for a plugin
 */
export interface CommandDefinition {
    name: string;
    description: string;
    aliases?: string[];
    execute: (args: string[], context: PluginContext) => Promise<void>;
}
/**
 * Tool definition for a plugin
 */
export interface ToolDefinition {
    name: string;
    description: string;
    schema: Record<string, any>;
    execute: (args: Record<string, any>, context: PluginContext) => Promise<any>;
}
/**
 * Base plugin class for planning and execution plugins
 */
export declare abstract class PlanningPlugin {
    protected context: PluginContext;
    protected commands: Map<string, CommandDefinition>;
    protected tools: Map<string, ToolDefinition>;
    constructor(context: PluginContext);
    /**
     * Initialize the plugin
     */
    abstract initialize(): Promise<void>;
    /**
     * Register a command
     */
    protected registerCommand(command: CommandDefinition): void;
    /**
     * Register a tool
     */
    protected registerTool(tool: ToolDefinition): void;
    /**
     * Get all registered commands
     */
    getCommands(): CommandDefinition[];
    /**
     * Get all registered tools
     */
    getTools(): ToolDefinition[];
    /**
     * Execute a command
     */
    executeCommand(name: string, args: string[]): Promise<void>;
    /**
     * Execute a tool
     */
    executeTool(name: string, args: Record<string, any>): Promise<any>;
    /**
     * Log a message
     */
    protected log(message: string, level?: "debug" | "info" | "warn" | "error"): Promise<void>;
    /**
     * Show a toast notification
     */
    protected toast(message: string, type?: "info" | "success" | "error"): Promise<void>;
}
/**
 * Create an OpenCode plugin from a PlanningPlugin instance
 */
export declare function createOpenCodePlugin(plugin: PlanningPlugin): Plugin;
//# sourceMappingURL=plugin.d.ts.map