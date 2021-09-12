#!/usr/bin/env lsc
#
{Client} = require \tplink-smarthome-api

const EMETER_UPDATE_TIMEOUT = 3s
const EVT_METER_UPDATE = 'emeter-realtime-update'

const PREFIX = '%'
const GROUP = 'smartplug'


class SmartPlug
  (@parent, @index, @id, @plug, @info) ->
    self = @
    self.name = info.name
    f = -> return self.at_timer_expiry!
    plug.on EVT_METER_UPDATE, (m) -> return self.on_meter_update m
    plug.startPolling 1000ms
    self.timer = setInterval f, 1000ms
    self.counter = 0
    self.last_updated = Date.now!
  
  on_meter_update: (meter) ->
    {index, id, info, name, parent} = self = @
    self.counter = 0
    try
      tokens = [PREFIX, parent.get_next_packet_index!.toString!, GROUP, "name:#{name}", "id:#{id}"]
      xs = [ "#{k}=#{v}" for k, v of meter ]
      tokens = tokens ++ xs
      # console.log "#{index}:#{id}:#{name}:meter => #{JSON.stringify meter}"
      console.log tokens.join '\t'
    catch
      console.dir e

  at_timer_expiry: ->
    {index, id, counter, timer, parent, plug, name} = self = @
    self.counter = counter + 1
    # console.error "#{index}:#{id}:#{name}: counter = #{self.counter}"
    return unless self.counter >= EMETER_UPDATE_TIMEOUT
    console.error "#{index}:#{id}:#{name}: no udpates more than #{EMETER_UPDATE_TIMEOUT}s, assuming the plug is offline"
    plug.removeAllListeners EVT_METER_UPDATE
    plug.stopPolling!
    clearInterval timer
    parent.remove id, self
    

class Discovery
  (@opts={}) ->
    self = @
    self.plugs = {}
    self.index = 0
    self.packet_index = 0
    client = self.client = new Client!
    client.on 'plug-new', (p) -> return self.add_and_start p, 'plug-new'
    client.on 'plug-online', (p) -> return self.add_and_start p, 'plug-online'
    client.on 'plug-offline', (p) -> return self.on_plug_offline p

  start: (done) ->
    {client} = self = @
    client.startDiscovery!
    return done!

  add_and_start: (p, evt) ->
    {plugs, index} = self = @
    {deviceId, deviceType, hardwareVersion, id, mac, macNormalized, model, name, softwareVersion, sysInfo} = p
    console.error "#{evt} => #{deviceId} / #{mac} / #{deviceType} / #{name}"
    info = {deviceId, deviceType, hardwareVersion, id, mac, macNormalized, model, name, softwareVersion, sysInfo}
    ref = plugs[deviceId]
    return if ref?
    self.index = index + 1
    plugs[deviceId] = plug = new SmartPlug self, self.index, deviceId, p, info
  
  remove: (id, plug) ->
    delete @plugs[id]

  on_plug_offline: (p) ->
    {deviceId, deviceType, hardwareVersion, id, mac, macNormalized, model, name, softwareVersion, sysInfo} = p
    xs = {deviceId, deviceType, hardwareVersion, id, mac, macNormalized, model, name, softwareVersion, sysInfo}
    return console.error "#{new Date!}\tplug-offline => #{JSON.stringify xs}"

  get_next_packet_index: ->
    {packet_index} = self = @
    self.packet_index = packet_index + 1
    return self.packet_index
  


d = new Discovery!
d.start (err) -> 
  return unless err?
  console.error "start discovery but failed, #{err}"
  console.dir err
