# Hubot Nurph Adapter

## Description

This is the [Nurph](http://Nurph.com) adapter for Hubot.

## Installation

* Add `hubot-nurph` as a dependency in your hubot's `package.json`
* Install dependencies with `npm install`
* Run hubot with `bin/hubot -a nurph

### Note if running on Heroku

You will need to change the process type from `app` to `web` in the `Procfile`.

## Usage

You will need to set some environment variables to use this adapter.

### Heroku

    % heroku config:add HUBOT_NURPH_KEY="key"
    % heroku config:add HUBOT_NURPH_TOKEN="token"
    % heroku config:add HUBOT_NURPH_USER_ID="id"
    % heroku config:add HUBOT_NURPH_USER_NAME="name"
    % heroku config:add HUBOT_NURPH_USER_AVATAR="url"
    % heroku config:add HUBOT_NURPH_CHANNELS="channel1, channel2"

### Non-Heroku environment variables

    % export HUBOT_NURPH_KEY="key"
    % export HUBOT_NURPH_TOKEN="token"
    % export HUBOT_NURPH_USER_ID="id"
    % export HUBOT_NURPH_USER_NAME="name"
    % export HUBOT_NURPH_USER_AVATAR="url"
    % export HUBOT_NURPH_CHANNELS="channel1, channel2"

## Contribute

Here's the most direct way to get your work merged into the project.

1. Fork the project
2. Clone down your fork
3. Create a feature branch
4. Hack away and add tests, not necessarily in that order
5. Make sure everything still passes by running tests
6. If necessary, rebase your commits into logical chunks without errors
7. Push the branch up to your fork
8. Send a pull request for your branch

## Copyright

Copyright &copy; Neil Cauldwell. See LICENSE for details.

