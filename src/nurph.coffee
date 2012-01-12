Robot        = require('hubot').robot()
Adapter      = require('hubot').adapter()

HTTPS        = require 'https'
EventEmitter = require('events').EventEmitter
net          = require('net')
tls          = require('tls')
xstreamly    = require('xstreamly-client')

class Nurph extends Adapter
  send: (user, strings...) ->
    strings.forEach (str) =>
      @bot.write user.channel, {"type": "message", "content": str}

  reply: (user, strings...) ->
    strings.forEach (str) =>
      @send user, "@#{user.name} #{str}"

  run: ->
    self = @
    channels = process.env.HUBOT_NURPH_CHANNELS.split(',')

    bot = new NurphClient()
    console.log bot

    ping = (channel)->
      setInterval ->
        bot.write channel, {type: "ping"}
      , 25000

    bot.on "Ready", (channel)->
      message = {"channel": channel, "type": "connect"}
      bot.write channel, message
      ping channel

    bot.on "Users", (message)->
      for user in message.users
        self.userForId(user.id, user)

    bot.on "TextMessage", (channel, message)->
      unless self.name == message.user.name
        # Replace "@mention" with "mention: ", case-insensitively
        regexp = new RegExp "^@#{self.name}", 'i'
        content = message.content.replace(regexp, "#{self.name}:")

        self.receive new Robot.TextMessage self.userForMessage(channel, message), content

    bot.on "EnterMessage", (channel, message) ->
      unless self.name == message.user.name
        self.receive new Robot.EnterMessage self.userForMessage(channel, message)

    bot.on "LeaveMessage", (channel, message) ->
      unless self.name == message.user.name
        self.receive new Robot.LeaveMessage self.userForMessage(channel, message)

    for channel in channels
      bot.sockets[channel] = bot.createSocket(channel)

    @bot = bot

  userForMessage: (channel, message)->
    author = @userForId(message.user.id, message.user)
    author.channel = channel
    author

exports.use = (robot) ->
  new Nurph robot

class NurphClient extends EventEmitter
  constructor: ->
    @domain        = 'nurph.com'
    @encoding      = 'utf8'
    @port          = ''
    @sockets       = {}

  createSocket: (channel) ->
    self = @

    socket = tls.connect @port, @domain, ->
      console.log("Connected to channel #{channel}.")
      self.emit "Ready", channel

    #callback
    socket.on 'data', (data) ->
      for line in data.split '\n'
        message = if line is '' then null else JSON.parse(line)

        if message
          console.log "From channel #{channel}: #{line}"
          if message.type == "users"
            self.emit "Users", message
          if message.type == "message"
            self.emit "TextMessage", channel, message
          if message.type == "join"
            self.emit "EnterMessage", channel, message
          if message.type == "leave"
            self.emit "LeaveMessage", channel, message
          if message.type == "error"
            self.disconnect channel, message.message

    socket.addListener "eof", ->
      console.log "eof"
    socket.addListener "timeout", ->
      console.log "timeout"
    socket.addListener "end", ->
      console.log "end"

    socket.setEncoding @encoding

    socket

  write: (channel, arguments) ->
    self = @
    @sockets[channel]

    if @sockets[channel].readyState != 'open'
      return @disconnect 'cannot send with readyState: ' + @sockets[channel].readyState

    message = JSON.stringify(arguments)
    console.log "To room #{channel}: #{message}"

    @sockets[channel].write message, @encoding

  disconnect: (channel, why) ->
    if @sockets[channel] != 'closed'
      @sockets[channel]
      console.log 'disconnected (reason: ' + why + ')'
