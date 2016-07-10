require 'slack-ruby-client'
require 'logging'
require 'clockwork'
require 'date'

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
  @last_post=client.files_upload(
    channels: '#random',
     as_user: true,
     content: "#{week_from_today} SHS
     1. Weekly Overview
     2. Negotiations and case management
     3. Personal workflow - issues, optimization, suggestions
     4. Tech tips",
     filename: 'document.txt',
     filetype: 'post',
     editable: true,
     initial_comment: 'Attached a file.'
  )
end

def create_wednesday_reminder client
  client.chat_postMessage(channel: '#random', text: "<!channel>: Please contribute to <#{last_post_url}|SHS agenda>", as_user: true)
end

def create_friday_reminder client
  client.chat_postMessage(channel: '#random', text: "<!channel>: Learn anything new this week? Add it to the <#{last_post_url}|SHS agenda>", as_user: true)
end

def week_from_today
  Date.today+7
end

def last_post_url
  @last_post&.file&.url_private
end
# listen for hello (connection) event - https://api.slack.com/events/hello
client.on :hello do
  logger.debug("Connected '#{client.self['name']}' to '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com.")
end

Clockwork.every(1.week, 'post.shs_agenda', at: 'Tuesday 13:00', tz: 'Europe/Berlin') { create_slack_post Slack::Web::Client.new }
Clockwork.every(1.week, 'post.reminder', at: 'Wednesday 16:00', tz: 'Europe/Berlin') { create_wednesday_reminder Slack::Web::Client.new }
Clockwork.every(1.week, 'post.reminder', at: 'Friday 16:00', tz: 'Europe/Berlin') { create_friday_reminder Slack::Web::Client.new }
