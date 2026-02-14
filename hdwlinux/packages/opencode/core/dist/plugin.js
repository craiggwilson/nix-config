/**
 * OpenCode Plugin Interface
 *
 * Defines the core plugin interface for the planning and execution suite.
 */
/**
 * Base plugin class for planning and execution plugins
 */
export class PlanningPlugin {
    constructor(context) {
        this.commands = new Map();
        this.tools = new Map();
        this.context = context;
    }
    /**
     * Register a command
     */
    registerCommand(command) {
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
    registerTool(tool) {
        this.tools.set(tool.name, tool);
    }
    /**
     * Get all registered commands
     */
    getCommands() {
        return Array.from(this.commands.values());
    }
    /**
     * Get all registered tools
     */
    getTools() {
        return Array.from(this.tools.values());
    }
    /**
     * Execute a command
     */
    async executeCommand(name, args) {
        const command = this.commands.get(name);
        if (!command) {
            throw new Error(`Command not found: ${name}`);
        }
        await command.execute(args, this.context);
    }
    /**
     * Execute a tool
     */
    async executeTool(name, args) {
        const tool = this.tools.get(name);
        if (!tool) {
            throw new Error(`Tool not found: ${name}`);
        }
        return await tool.execute(args, this.context);
    }
    /**
     * Log a message
     */
    async log(message, level = "info") {
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
    async toast(message, type = "info") {
        // This would be implemented via the TUI event hook
        await this.log(`[${type.toUpperCase()}] ${message}`);
    }
}
/**
 * Create an OpenCode plugin from a PlanningPlugin instance
 */
export function createOpenCodePlugin(plugin) {
    return async (ctx) => {
        await plugin.initialize();
        const hooks = {};
        // Register TUI command hook
        hooks["tui.command.execute"] = async (input, output) => {
            const commandName = input.command;
            const args = input.args || [];
            try {
                const command = plugin["commands"].get(commandName);
                if (command) {
                    await plugin.executeCommand(commandName, args);
                    output.handled = true;
                }
            }
            catch (error) {
                await plugin["log"](`Error executing command ${commandName}: ${error}`, "error");
                throw error;
            }
        };
        return hooks;
    };
}
//# sourceMappingURL=plugin.js.map