require 'httparty'

module Helpers
  def send_time_to_slack
    HTTParty.post(settings.slack_incoming_url,
                  body: {
                    channel: settings.slack_channel,
                    username: settings.slack_username,
                    text: ":heart: _#{compute_time_in_english last_record}_ :heart:",
                    icon_emoji: settings.slack_avatar
                  }.to_json,
                  headers: {'content-type' => 'application/json'}
                 )
  end

  def parse_time!(record)
    record.each { | k, v | record[k] = Time.parse v }
  end

  def compute_time(timer)
    return unless has_the_time? timer
    parse_time!(timer) unless timer["start"].class == Time

    t = timer["stop"] - timer["start"]
    mm, ss = t.divmod(60)
    hh, mm = mm.divmod(60)
    [hh, mm, ss]
  end

  def compute_time_in_english(timer)
    times = compute_time(timer)
    unless times.nil?
      "%d hours, %d minutes and %d seconds" % times
    end
  end

  def has_the_time?(timer)
    timer["stop"] >= timer["start"]
  rescue
    false
  end

  def new_record_id
    "release:#{Time.now.to_i}"
  end

  def last_record_id
    #TODO: use redis sorted sets
    $redis.smembers('times').sort.last
  end

  def last_record
    $redis.hgetall last_record_id
  end
end
