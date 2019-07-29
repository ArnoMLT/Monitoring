from NSCP import Registry, Core, status, log, log_debug
g_plugin_id = 0


def query_to_nsca(channel, source, command, status, message, perf):
  #global g_plugin_id
  global new_message

  log("Sending: %s"%message)
  core = Core.get(g_plugin_id)
  (code, message, perf) = core.simple_query(command, [])
  
  new_message = message.replace('\r\n', '\n')
  #message = message.replace('\n\n', '\n')
  log_debug(message)
  log_debug("command : %s"%command)
  log_debug("source : %s"%source)

  if new_message != message:
    log("win type file detected")
  
  core.simple_submit('NSCA', command, code, message.encode('utf-8'), perf)


def init(plugin_id, plugin_alias, script_alias):
  global g_plugin_id
  g_plugin_id = plugin_id
  reg = Registry.get(plugin_id)
  reg.simple_subscription('python_handler_to_nsca', query_to_nsca)
