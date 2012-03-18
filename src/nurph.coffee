Robot        = require('hubot').robot()
Adapter      = require('hubot').adapter()

HTTPS        = require 'https'
EventEmitter = require('events').EventEmitter
net          = require('net')
Pusher    	 = require('node-pusher')

class Nurph extends Adapter
  send: (user, strings...) ->
    strings.forEach (str) =>
      # Example attributes published to a Pusher channel...
      #
      #   "position":452
      #   "retracted":false
      #   "created_at":"2012-01-27T17:33:24+00:00"
      #   "sender": {
      # 	  "avatar_url":
      # 	  "name":
      # 	  "location":"on Nurph, SMS, Twitter, & Web."
      # 	  "url":"http://a1.twimg.com/profile_images/1450887565/AZO_glow_normal.png"
      # 	  "id":4
      # 	  "display_name":"Nurph"
      # 	  "time_zone":null
      # 	  "status":null
      # 	  "biography":null
      # 	 }
      # 	"id":6983
      # 	"type":"remark"
      # 	"content":"@NeilCauldwell welcome to the #pizza Channel"
      # 	"member":null
      #
      console.log "I'm trying to send a message to channel: #{user.channel} with type:'remark', content:#{str}, created_at:#{(new Date()).toString()}, sender:{ avatar_url:#{process.env.HUBOT_NURPH_USER_AVATAR}, name:#{process.env.HUBOT_NURPH_USER_NAME} }"
      @bot.write user.channel, { "type": "remark", "content": str, "created_at": (new Date()).toString(), "sender":{ "avatar_url":process.env.HUBOT_NURPH_USER_AVATAR, "name":process.env.HUBOT_NURPH_USER_NAME } }

  reply: (user, strings...) ->
    strings.forEach (str) =>
      @send user, "@#{user.name} #{str}"

  run: ->
    self = @
    options =
      app_id : process.env.HUBOT_NURPH_APP_ID
      app_key : process.env.HUBOT_NURPH_APP_KEY
      app_secret : process.env.HUBOT_NURPH_APP_SECRET
      user_id : process.env.HUBOT_NURPH_USER_ID
      user_name : process.env.HUBOT_NURPH_USER_NAME
      user_avatar : process.env.HUBOT_NURPH_USER_AVATAR
      channels : process.env.HUBOT_NURPH_CHANNELS.split(',')

    bot = new NurphClient(options)
    console.log bot

    bot.on "TextMessage", (channel, message)->
      unless self.robot.name == message.sender.name
        # Replace "@mention" with "mention: ", case-insensitively
        regexp = new RegExp "^@#{self.robot.name}", 'i'
        content = message.content.replace(regexp, "#{self.robot.name}:")

        self.receive new Robot.TextMessage self.userForMessage(channel, message), content
        console.log "I received a message of channel: #{channel}, message.type: #{message.type} and content: #{content}."

    bot.on "EnterMessage", (channel, message) ->
      unless self.robot.name == message.sender.name
        self.receive new Robot.EnterMessage self.userForMessage(channel, message)

    bot.on "LeaveMessage", (channel, message) ->
      unless self.robot.name == message.sender.name
        self.receive new Robot.LeaveMessage self.userForMessage(channel, message)

    for channel in options.channels
      bot.sockets[channel] = bot.createSocket(channel)

    @bot = bot

  userForMessage: (channel, message)->
    author = @userForId(message.sender.id, message.sender)
    author.channel = channel
    author

exports.use = (robot) ->
  new Nurph robot

class NurphClient extends EventEmitter
  constructor: (options) ->
    if options.app_id? and options.app_key? and options.app_secret? and options.user_id? and options.user_name? and options.user_avatar? and options.channels?
      @app_id     = options.app_id
      @app_key    = options.app_key
      @app_secret = options.app_secret
      @channels   = options.channels
      @client     = new Pusher({
        appId: @app_id,
        key: @app_key,
        secret: @app_secret
      })
      @sockets    = {}

    else
      throw new Error("Not enough parameters provided. I need an app_id, an app_key, an app_secret, a user_id, a user_name, a user_avatar_url, and at least one channel.")

  createSocket: (channel) ->
    self = @
    console.log "@client = #{@client}"

    socket = @client.subscribe channel, {
      userId: process.env.HUBOT_NURPH_USER_ID,
      userInfo: {
        name: process.env.HUBOT_NURPH_USER_NAME,
        profilePic: process.env.HUBOT_NURPH_USER_AVATAR
      }
    } , ->
    console.log("Connected to channel #{channel}.")
    self.emit "Ready", channel

    #callback
    socket.bind_all (eventType, message) ->
      console.log "eventType: #{eventType}"
      console.log "From channel #{channel}: #{message.sender.name}: #{message.content}"
      if message.type == "remark"
        self.emit "TextMessage", channel, message
      if message.type == "pusher:member_added"
        self.emit "EnterMessage", channel, message
      if message.type == "pusher:member_removed"
        self.emit "LeaveMessage", channel, message

    socket

  write: (channel, arguments) ->
    self = @
    @sockets[channel]

    message = JSON.stringify(arguments)
    console.log "To channel #{channel}: #{message}"

    @sockets[channel].trigger 'remark', message

  disconnect: (channel, why) ->
    if @sockets[channel] != 'closed'
      @sockets[channel]
      @client.stop()
      console.log 'disconnected (reason: ' + why + ')'
