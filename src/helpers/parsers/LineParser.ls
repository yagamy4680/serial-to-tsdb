
class Packet
  (@line) ->
    self = @
    [prefix, index, measurement, ...data] = tokens = self.tokens = line.split '\t'
    self.prefix = prefix
    xs = {prefix, index, measurement, data}
    # console.log "tokens => #{JSON.stringify xs}, prefix length = #{prefix.length}"
    return unless prefix is '%'
    self.index = parseInt index
    self.measurement = measurement
    self.fields = {}
    self.tags = {}
    [ (self.parse_field_or_tag str) for str in data ]


  parse_field_or_tag: (str) ->
    {fields, tags} = self = @
    if -1 is str.indexOf ':'
      [key, value] = str.split '='
      value = if -1 is value.indexOf '.' then parseInt value else parseFloat value
      fields[key] = value
    else
      [key, value] = str.split ':'
      tags[key] = value
    return

  to_json: ->
    {measurement, fields, tags} = self = @
    return {measurement, fields, tags}


module.exports = exports = (line) ->
  p = new Packet line
  return p
