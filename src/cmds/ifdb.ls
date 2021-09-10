{CreateConnection} = require \../helpers/connection
ParseLine = require \../helpers/parsers/LineParser
DatabaseClient = require \../helpers/databases/influxdb
require! <[pino path]>

const EXAMPLE_CMD = '$0 influxdb serial:///dev/tty.usbmodem123456781?settings=b115200,8,N,1&name=MPU'
const EXAMPLE_DESC = '''parse ...
'''
const EPILOG = '''
Supported connection strings:

  SerialDriver: serial:///dev/tty.usbmodem123456781

  TcpDriver: tcp://10.42.0.213:9090

  ExecDriver: exec:///tmp/serial-to-tsdb/tests/si-get-currentLoad.js


All connection strings support a query parameter `name` to specify its name.

ExecDriver allows to specify `arg` several times as arguments to run the specified executable file, for example `arg=aa&arg=bb&arg=cc` is to run the executeable file with arguments `aa bb cc`.
'''

ERR_EXIT = (logger, err) ->
  logger.error err
  return process.exit 1


module.exports = exports =
  command: "ifdb <connectionString>"
  describe: "parse line data from serial port, and write into influxdb"

  builder: (yargs) ->
    yargs
      .example EXAMPLE_CMD, EXAMPLE_DESC
      .epilogue EPILOG
      .alias \c, \config
      .describe \c, "influxdb database configuration, YAML format"
      .alias \v, \verbose
      .default \v, no
      .describe \v, "verbose output"
      .boolean 'v'
      .demand <[v c]>


  handler: (argv) ->
    {config} = global
    {verbose, connectionString, config} = argv
    console.log JSON.stringify argv, ' ', null
    console.log "verbose = #{verbose}"
    level = if verbose then 'trace' else 'info'
    prettyPrint = translateTime: 'SYS:HH:MM:ss.l', ignore: 'pid,hostname'
    console.log "prettyPrint => #{JSON.stringify prettyPrint}"
    console.log "config => #{config}"
    logger = pino {prettyPrint, level}
    db = new DatabaseClient logger, config
    c = CreateConnection logger, 1, connectionString
    c.set_data_cb (line) -> 
      line = line.replace /\u0000/g, ''
      line = line.replace /\\u0000/g, ''
      p = ParseLine line
      return logger.info "[skip] #{p.line}" unless p.prefix is "%"
      data = p.to_json!
      timestamp = Date.now!
      db.append {data, timestamp}
    (err) <- c.start
    return ERR_EXIT logger, err if err?
