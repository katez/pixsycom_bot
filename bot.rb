require 'slack-ruby-client'
require 'logging'
require 'clockwork'

logger = Logging.logger(STDOUT)
logger.level = :debug

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  if not config.token
    logger.fatal('Missing ENV[SLACK_TOKEN]! Exiting program')
    exit
  end
end

client = Slack::RealTime::Client.new

def create_slack_post client
  # client.chat_postMessage(channel: '#random', text: 'Hello World', as_user: false)
  client.files_upload(
    channels: '#random',
     as_user: true,
     content: 'DATE SHS
     1. Weekly Overview
     2. Negotiations and case management
     3. Personal workflow - issues, optimization, suggestions
     4. Tech tips',
     filename: 'document.txt',
     filetype: 'post',
     editable: true,
     initial_comment: 'Attached a file.'
  )
end


# listen for hello (connection) event - https://api.slack.com/events/hello
client.on :hello do
  logger.debug("Connected '#{client.self['name']}' to '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com.")
end

Clockwork.every(1.week, 'post.shs_agenda', at: 'Tuesday 13:00') { create_slack_post Slack::Web::Client.new }
