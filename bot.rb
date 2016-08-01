require 'slack-ruby-client'
require 'logging'
require 'clockwork'
require 'date'
require 'togglv8'

CHANNEL = '#superhero'
USER_TOGGL_TO_SLACK_MAPPING = {
  2071434 => 'kt'
}
MANGEMENT_USERS = [
  2340030, #alexandra
  2346716 #barbara
]

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
  # client.chat_postMessage(channel: CHANNEL, text: 'Hello World', as_user: false)
  last_post=client.files_upload(
    channels: CHANNEL,
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
  set_last_post_url(last_post.file.url_private)
end

def last_post_url
  File.read('last_post_url') rescue nil
end

def set_last_post_url last_post_url
  File.open('last_post_url', 'wb') { |file| file.write(last_post_url) }
end

def create_direct_message_nudge client, user
  client.chat_postMessage(channel: user, text: "It looks like you haven't logged your time in the last 30 minutes", as_user: true)
end

def create_wednesday_reminder client
  client.chat_postMessage(channel: CHANNEL, text: "<!channel>: Please contribute to <#{last_post_url}|SHS agenda>", as_user: true)
end

def create_friday_reminder client
  client.chat_postMessage(channel: CHANNEL, text: "<!channel>: Learn anything new this week? Add it to the <#{last_post_url}|SHS agenda>", as_user: true)
end

def week_from_today
  Date.today+7
end

def workspace_id
  @token ||= begin
    client = TogglV8::API.new(ENV['TOGGL_TOKEN'])
    me = client.me
    workspaces = client.my_workspaces(me)
    workspaces.first['id']
  end
end

def get_users_from_toggl toggl_client
  toggl_client.users(workspace_id)
end

def nudge_user_toggl_time slack_client, toggl_client
  all_users = get_users_from_toggl(toggl_client)
  relevant_users = find_relevant_users(all_users)
  lazy_users = find_not_logged_in_users(relevant_users)
  direct_message_users(lazy_users)
end

# listen for hello (connection) event - https://api.slack.com/events/hello
client.on :hello do
  logger.debug("Connected '#{client.self['name']}' to '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com.")
end

Clockwork.every(1.week, 'post.shs_agenda', at: 'Tuesday 13:00', tz: 'Europe/Berlin') { create_slack_post Slack::Web::Client.new }
Clockwork.every(1.week, 'post.reminder', at: 'Wednesday 16:00', tz: 'Europe/Berlin') { create_wednesday_reminder Slack::Web::Client.new }
Clockwork.every(1.week, 'post.reminder', at: 'Friday 16:00', tz: 'Europe/Berlin') { create_friday_reminder Slack::Web::Client.new }

#Clockwork.every(3.minutes, 'post.message.nudge') { nudge_user_toggl_time Slack::Web::Client.new, TogglV8::API.new(ENV['TOGGL_TOKEN']) }
