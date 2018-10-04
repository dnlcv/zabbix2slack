#!/usr/bin/env ruby

require 'json'
require 'uri'
require 'net/http'

WEBHOOK  = "https://hooks.slack.com/services/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"
USER     = "Zabbix-Events"
@type    = "plain"
@emoji   = ":fog:"
@message = nil
@payload = {'username' => USER}

def usage()
  puts "Usage:  #{$0} TO SUBJECT MESSAGE [@type]"
  puts "TO      --> Slack channel/user"
  puts "SUBJECT --> Alert subject"
  puts "MESSAGE --> Alert message (leave empty if you don't want to provide a message)"
  puts "@type    --> This refers to the message type: plain or json"
  puts "\nNOTE: Set your subject to begin with PROBLEM, OK, RECOVER(Y|ED) or WARN(ING) to customize the user icon."
end

# Make sure we are getting 3 or 4 parameters from zabbix
if ARGV.size < 3 || ARGV.size > 4
  puts "ERROR: Wrong number of parameters."
  usage();
  exit 1
#else
#  # Check for empty parameters
#  ARGV.each do|a|
#    if a.empty?
#      puts "ERROR: Empty parameters are not supported."
#      usage();
#      exit 1
#    end
#  end
end

# Set the message type
if ARGV.size == 4
  @type = ARGV[3].downcase
end

# Validate the channel format
if ARGV[0] !~ /^(@|#)[\w\-\.\ ]+/
  puts "ERROR: Bad format for slack channel/user."
  usage();
  exit 1
else
  # Set the channel in the payload
  @payload['channel'] = ARGV[0]
end

# Based on the subject select an emoji
case ARGV[1]
  when /^PROBLEM/i
    @emoji = ":thunder_cloud_and_rain:" 
  when /^(WARN(ING)?)/i
    @emoji = ":barely_sunny:" 
  when /^(OK|RECOVER(Y|ED)?)/i
    @emoji = ":sunny:" 
  else
    if ARGV[1].empty?
      puts "ERROR: Empty subject. Try to pass a value."
      puts "OPTIONAL: Set your subject to begin with PROBLEM, OK, RECOVER(Y|ED) or WARN(ING) to customize the user icon."
      usage();
      exit 1
    end
end

# Set the emoji icon in the payload
@payload['icon_emoji'] = @emoji

# Set the message based on the TYPE
case @type
  when 'plain'
    if (ARGV[1] =~ /^(PROBLEM|OK|RECOVER(Y|ED)?|WARN(ING)?)i$/i) && (!ARGV[2].empty?)
      @payload['message'] = "#{ARGV[1]}: #{ARGV[2]}"
    elsif (!ARGV[2].empty?)
      @payload['message'] = "#{ARGV[1]}\n#{ARGV[2]}"
    elsif (ARGV[2].empty?)
      @payload['message'] = "#{ARGV[1]}"
    end
  when 'json'
    # Parse the JSON message
    begin
      @message = JSON.parse(ARGV[2])
    rescue Exception => e
      puts "ERROR: Caught Exception: #{e.inspect}"
      exit 1
    end
    if @message.has_key?('attachments')
      @payload.merge!(@message)
    else
      puts "ERROR: JSON messages are only allowed for creating attached messages."
      exit 1
    end
  else
    puts "ERROR: Bad Type. Supported values are plain or json."
    usage();
    exit 1
end

#puts "ARGV Size => #{ARGV.size}"
#puts "ARGV => #{ARGV.inspect}"
puts "PAYLOAD => #{@payload.inspect}"

uri = URI(WEBHOOK)
res = Net::HTTP.post_form(uri, 'payload' => @payload.to_json)
puts res.body
