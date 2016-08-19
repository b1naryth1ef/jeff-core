module jeffcore;

import std.array;
import dscord.core,
       dscord.util.emitter;

class CorePlugin : Plugin {
  this() {
    super();
  }

  @Command("ping")
  void onPing(CommandEvent event) {
    event.msg.reply("pong");
  }

  Plugin pluginCommand(CommandEvent e, string action) {
    if (e.args.length != 1) {
      e.msg.replyf("Must provide a plugin name to %s", action);
      throw new EmitterStop;
    }

    if ((e.args[0] in this.bot.plugins) is null) {
      e.msg.replyf("Unknown plugin `%s`", e.args[0]);
      throw new EmitterStop;
    }

    return this.bot.plugins[e.args[0]];
  }

  @Command("reload")
  @CommandGroup("plugin")
  @CommandDescription("reload a plugin")
  @CommandLevel(Level.ADMIN)
  void onPluginReload(CommandEvent e) {
    auto plugin = this.pluginCommand(e, "reload");

    // Defer the reload to avoid being within the function stack of the DLL, or
    //  smashing our stack while we're in another event handler.
    e.event.defer({
      plugin = this.bot.dynamicReloadPlugin(plugin);
      e.msg.replyf("Reloaded plugin `%s`", plugin.name);
    });
  }

  @Command("unload")
  @CommandGroup("plugin")
  @CommandDescription("unload a plugin")
  @CommandLevel(Level.ADMIN)
  void onPluginUnload(CommandEvent e) {
    auto plugin = this.pluginCommand(e, "unload");

    // Similar to above, defer unloading the plugin
    e.event.defer({
      // Send the message first or 'plugin' will nullref
      e.msg.replyf("Unloaded plugin `%s`", plugin.name);
      this.bot.unloadPlugin(plugin);
    });
  }

  @Command("load")
  @CommandGroup("plugin")
  @CommandDescription("load a plugin by path")
  @CommandLevel(Level.ADMIN)
  void onPluginLoad(CommandEvent e) {
    if (e.args.length != 1) {
      e.msg.reply("Must provide a DLL path to load");
      return;
    }

    // Note: this is super unsafe, should always be owner-only
    auto plugin = this.bot.dynamicLoadPlugin(e.args[0], null);
    e.msg.replyf("Loaded plugin `%s`", plugin.name);
  }

  @Command("list")
  @CommandGroup("plugin")
  @CommandDescription("list all plugins")
  @CommandLevel(Level.ADMIN)
  void onPluginList(CommandEvent e) {
    e.msg.replyf("Plugins: `%s`", this.bot.plugins.keys.join(", "));
  }

  @Command("save")
  @CommandDescription("save all storage")
  @CommandLevel(Level.ADMIN)
  void onSave(CommandEvent e) {
    foreach (plugin; this.bot.plugins.values) {
      if (plugin.storage) {
        plugin.storage.save();
      }
    }
    e.msg.reply("Saved all storage!");
  }
}

extern (C) Plugin create() {
  return new CorePlugin;
}
