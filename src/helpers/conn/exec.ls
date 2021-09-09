require! <[byline]>
EventEmitter = require \events
{spawn} = require \child_process
{BaseDriver} = require \./base

##
# Startup a ExecClient with given config string (similar to socat):
#
# e.g. The full url `exec:///tmp/serial-to-tsdb/tests/si-get-currentLoad.js?name=currentLoad` is composed of 
#      following fields:
#         name = currentLoad
#         pathname = /tmp/serial-to-tsdb/tests/si-get-currentLoad.js
#
module.exports = exports = class TcpDriver extends BaseDriver
  (pino, @id, @name, @uri, @tokens) ->
    self = @
    self.className = "ExecDriver"
    super ...
    {pathname, qs} = tokens
    {arg} = qs
    arg = [] unless arg? and Array.isArray arg
    self.pathname = pathname
    self.args = arg
    self.logger.debug JSON.stringify {id, name, pathname}

  ##
  # Write a chunk of bytes as data to remote. Subclass of the BaseDriver
  # needs to overwrite this function.
  #
  write_internally: (chunk) ->
    # return @tcp.write chunk
    return # do nothing!!

  ##
  # Establish a connection to the target. Subclass of the BaseDriver
  # needs to overwrite this function. 
  #
  connect_internally: ->
    {pathname, args, logger} = self = @
    child = self.child = spawn pathname, args, {shell: yes}
    stdout = self.stdout = byline child.stdout
    stderr = self.stderr = byline child.stderr
    stdout.on 'data', (buffer) -> return self.on_data buffer.toString!
    stderr.on 'data', (buffer) -> return logger.error buffer.toString!
    child.on 'close', (code) -> return self.on_close "code = #{code}"
    return self.on_connected!

  on_error: (err) ->
    {logger, name} = self = @
    logger.info "<#{name}>: at_error(err) => #{err}"
    logger.error err
  
  on_close: (err=null) ->
    {logger, name} = self = @
    logger.info "<#{name}>: at_close()"
    self.clean_and_reset!

  clean_and_reset: ->
    {child, stdout, stderr} = self = @
    stdout.removeAllListeners \data
    stderr.removeAllListeners \data
    child.removeAllListeners \close
    self.child = null
    self.stdout = null
    self.stderr = null
    self.on_disconnected!
