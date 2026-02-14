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
  client: any; // OpenCode SDK client
  $: any; // Bun shell API
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
export abstract class PlanningPlugin {
  protected context: PluginContext;
  protected commands: Map<string, CommandDefinition> = new Map();
  protected tools: Map<string, ToolDefinition> = new Map();

  constructor(context: PluginContext) {
    this.context = context;
  }

  /**
   * Initialize the plugin
   */
  abstract initialize(): Promise<void>;

  /**
   * Register a command
   */
  protected registerCommand(command: CommandDefinition): void {
    this.commands.set(command.name, command);
    if (command.aliases) {
      for (const alias of command.aliases) {
        this.commands.set(alias, command);
      }
    }
  }

  /**
   * Register a tool
   */
  protected registerTool(tool: ToolDefinition): void {
    this.tools.set(tool.name, tool);
  }

  /**
   * Get all registered commands
   */
  getCommands(): CommandDefinition[] {
    return Array.from(this.commands.values());
  }

  /**
   * Get all registered tools
   */
  getTools(): ToolDefinition[] {
    return Array.from(this.tools.values());
  }

  /**
   * Execute a command
   */
  async executeCommand(name: string, args: string[]): Promise<void> {
    const command = this.commands.get(name);
    if (!command) {
      throw new Error(`Command not found: ${name}`);
    }
    await command.execute(args, this.context);
  }

  /**
   * Execute a tool
   */
  async executeTool(name: string, args: Record<string, any>): Promise<any> {
    const tool = this.tools.get(name);
    if (!tool) {
      throw new Error(`Tool not found: ${name}`);
    }
    return await tool.execute(args, this.context);
  }

  /**
   * Log a message
   */
  protected async log(message: string, level: "debug" | "info" | "warn" | "error" = "info"): Promise<void> {
    await this.context.client.app.log({
      body: {
        service: this.constructor.name,
        level,
        message,
      },
    });
  }

  /**
   * Show a toast notification
   */
  protected async toast(message: string, type: "info" | "success" | "error" = "info"): Promise<void> {
    // This would be implemented via the TUI event hook
    await this.log(`[${type.toUpperCase()}] ${message}`);
  }
}

/**
 * Create an OpenCode plugin from a PlanningPlugin instance
 */
export function createOpenCodePlugin(plugin: PlanningPlugin): Plugin {
  return async (ctx: PluginContext) => {
    await plugin.initialize();

    const hooks: Record<string, any> = {};

    // Register TUI command hook
    hooks["tui.command.execute"] = async (input: any, output: any) => {
      const commandName = input.command;
      const args = input.args || [];

      try {
        const command = plugin["commands"].get(commandName);
        if (command) {
          await plugin.executeCommand(commandName, args);
          output.handled = true;
        }
      } catch (error) {
        await plugin["log"](`Error executing command ${commandName}: ${error}`, "error");
        throw error;
      }
    };

    return hooks;
  };
}
