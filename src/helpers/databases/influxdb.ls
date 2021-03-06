require! <[js-yaml fs request url]>


FORMAT_KEY = (k) ->
  k = k.split '.' .join '_' 
  k = k.split '/' .join '_'
  return k


##
# InfluxDB line protocol tutorial
# 
# https://docs.influxdata.com/influxdb/v1.8/write_protocols/line_protocol_tutorial/
#
SERIALIZE = (m) ->
  {timestamp, data} = m
  {measurement, fields, tags} = data
  x0 = [ "#{FORMAT_KEY k}=#{v}" for k, v of tags ]
  x1 = [ "#{FORMAT_KEY k}=#{v}" for k, v of fields ]
  xs = [measurement] ++ x0
  xs = [(xs.join ","), x1, timestamp.toString!]
  return xs.join " "


class InfluxdbClient
  (@logger, @yml) ->
    self = @
    self.items = []
    config = self.config = js-yaml.load fs.readFileSync yml
    logger.info "yml => #{yml}"
    logger.info "config => #{JSON.stringify config}"
    f = -> return self.at_timer_expiry!
    setInterval f, 1000ms

  append: (m) ->
    {logger, items} = self = @
    line = SERIALIZE m
    logger.info line
    items.push line
  
  at_timer_expiry: ->
    {logger, items, config} = self = @
    return if items.length is 0
    self.items = []
    {token, bucket, org} = config
    {hostname} = xs = url.parse config.url
    # logger.info "flushing to influxdb (#{JSON.stringify xs}) ..."
    uri = config.url
    body = items.join '\n'
    precision = "ms"
    qs = {bucket, org, precision}
    headers =
      'Content-Type': "text/plain; charset=utf-8"
      'Authorization': "Token #{token}"
    opts = {uri, qs, headers, body}
    request.post opts, (err, rsp, body) ->
      return logger.error if err?
      return logger.error "influxdb (#{hostname}:#{bucket}:#{org}) response #{rsp.statusCode} => #{body}" unless rsp.statusCode is 204
      return logger.info "successfully write #{items.length} records (#{hostname}:#{bucket}:#{org})."


module.exports = exports = InfluxdbClient

