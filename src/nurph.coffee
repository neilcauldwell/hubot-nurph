Robot = require('hubot').robot()
Adapter = require('hubot').adapter()
Express = require('express')

class Nurph extends Adapter
  run: ->
    @waitingResponse = {}

    @app = Express.createServer Express.logger(), Express.bodyParser()

    @app.post '/rest/messsage', (req, res) =>
      console.log "Received Request"
      if !req.is 'json'
        res.json {status: 'failed', error: "request isn't json"}
        console.log "Error: request isn't json"
        return

      sender = req.body.sender?.name
      channel = req.body.channel
      content = req.body.content

      if !sender || !channel || !content
        res.json {status: 'failed', error: "request data missing"}
        console.log "Error: request data missing"
        return

      user = @userForId sender, name: sender, room: channel
      console.log user
      console.log "Req: " + sender + " - " + content
      @waitingResponse[user] = res
      message = new Robot.TextMessage user, content
      @receive message
      #timeout on waiting, if we run out of time we should
      #send a timeout response.
      user.timeoutId = setTimeout((() => @checkNoResponse(user)), 5000)

    port = 3000
    @app.listen port

    console.log "REST express server started and listening on port #{port}"

  checkNoResponse: (user) ->
    res = @waitingResponse?[user]
    if res?
      res.json({status: "failed", error: "request timed out"})
      @waitingResponse[user] = null
    user.timeoutId = null

  send: (user, strings...) ->
    console.log "#{user} + #{str}" for str in strings
    res = @waitingResponse?[user]
    if !res?
      console.log "Error: no user response object"
      return
    else
      console.log "Sending response"
      @waitingResponse[user] = null
      res.json({status: "reply", content: strings[0]})

    if user.timeoutId?
      clearTimeout user.timeoutId
      user.timeoutId = null

    console.log "Listeners: " + @robot.listeners.length

  reply: (user, strings...) ->
    @send user, strings...

  close: () ->

exports.use = (robot) ->
  new Nurph robot

