EventEmitter = require \events
require! <[net byline]>
{BaseDriver} = require \./base

##
# Startup a TcpClient with given config string (similar to socat):
#
# e.g. The full url `tcp://10.42.0.213:9090?name=EPC` is composed of 
#      following fields:
#         name = EPC
#         pathname = 
#         qs = {
#            settings: 'b115200:8:N:1'
#            }
#
module.exports = exports = class TcpDriver extends BaseDriver
  (pino, @id, @name, @uri, @tokens) ->
    self = @
    self.className = "TcpDriver"
    super ...
    {hostname, port, host} = tokens
    port = \2020 unless port?
    port = parseInt port
    self.packetFilter = null
    self.hostname = hostname
    self.port = port
    self.host = "#{hostname}:#{port}"
    self.logger.debug JSON.stringify {id, name, hostname, port, uri}

  ##
  # Write a chunk of bytes as data to remote. Subclass of the BaseDriver
  # needs to overwrite this function.
  #
  write_internally: (chunk) ->
    return @tcp.write chunk

  ##
  # Establish a connection to the target. Subclass of the BaseDriver
  # needs to overwrite this function. 
  #
  connect_internally: ->
    {logger, name, configs, opts, hostname, port} = self = @
    logger.info "<#{name}>: connecting to #{hostname.yellow} with port #{port} ..."
    tcp = self.tcp = new net.Socket!
    reader = self.reader = byline tcp
    reader.on \data, (buffer) -> return self.process_data buffer
    tcp.on \error, (err) -> return self.on_error err
    tcp.on \close, -> return self.on_close!
    <- tcp.connect port, hostname
    logger.info "<#{name}>: connected to #{hostname.yellow} with port #{port}"
    return self.on_connected!

  process_data: (buffer) ->
    {logger} = self = @
    text = buffer.toString!
    logger.debug "buffer => #{buffer.toString 'hex'} => #{text}"
    return self.on_data text

  on_error: (err) ->
    {logger, name} = self = @
    logger.info "<#{name}>: at_error(err) => #{err}"
    logger.error err
  
  on_close: (err=null) ->
    {logger, name} = self = @
    logger.info "<#{name}>: at_close()"
    self.clean_and_reset!

  clean_and_reset: ->
    {tcp, reader} = self = @
    reader.removeAllListeners \data
    tcp.removeAllListeners \error
    tcp.removeAllListeners \close
    self.tcp = null
    self.reader = null
    self.on_disconnected!