Robot        = require('hubot').robot()
Adapter      = require('hubot').adapter()

HTTPS        = require 'https'
EventEmitter = require('events').EventEmitter
net          = require('net')
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
    options =
      key : process.env.HUBOT_NURPH_KEY
      token : process.env.HUBOT_NURPH_TOKEN
      channels : process.env.HUBOT_NURPH_CHANNELS.split(',')

    bot = new NurphClient(options)
    console.log bot

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

    for channel in options.channels
      bot.sockets[channel] = bot.createSocket(channel)

    @bot = bot

  userForMessage: (channel, message)->
    author = @userForId(message.user.id, message.user)
    author.channel = channel
    author

exports.use = (robot) ->
  new Nurph robot

class NurphClient extends EventEmitter
  constructor: (options) ->
    if options.key? and options.token? and options.channels?
      @key        = options.key
      @token      = options.token
      @channels   = options.channels
      @client     = new xstreamly(@key, @token)
      @sockets    = {}

    else
      throw new Error("Not enough parameters provided. I need a key, a token, and at least one channel.")

  createSocket: (channel) ->
    self = @

    socket = @client.subscribe channel, { includeMyMessages:true } , ->
      console.log("Connected to channel #{channel}.")
      self.emit "Ready", channel

    #callback
    socket.bind_all (eventType, data) ->
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

    socket

  write: (channel, arguments) ->
    self = @
    @sockets[channel]

    if @sockets[channel].readyState != 'open'
      return @disconnect 'cannot send with readyState: ' + @sockets[channel].readyState

    message = JSON.stringify(arguments)
    console.log "To channel #{channel}: #{message}"

    @sockets[channel].write message, @encoding

  disconnect: (channel, why) ->
    if @sockets[channel] != 'closed'
      @sockets[channel]
      console.log 'disconnected (reason: ' + why + ')'
