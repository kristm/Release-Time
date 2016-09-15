require 'httparty'

module Helpers
  def send_time_to_slack
    HTTParty.post(settings.slack_incoming_url,
                  body: {
                    channel: settings.slack_channel,
                    username: settings.slack_username,
                    text: "_#{compute_time last_record}_",
                    icon_emoji: settings.slack_avatar
                  }.to_json,
                  headers: {'content-type' => 'application/json'}
                 )
  end

  def compute_time(timer)
    t = Time.parse(timer["stop"]) - Time.parse(timer["start"]) #why redis no store time?
    mm, ss = t.divmod(60)
    hh, mm = mm.divmod(60)
    "%d hours, %d minutes and %d seconds" % [hh, mm, ss]
  end

  def has_the_time?
    last_record["stop"] >= last_record["start"]
  rescue
    false
  end

  def new_record_id
    "release:#{Time.now.to_i}"
  end

  def last_record_id
    $redis.smembers('times').last
  end

  def last_record
    $redis.hgetall last_record_id
  end
end
