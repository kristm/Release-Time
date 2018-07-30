require 'httparty'

module Helpers
  RELEASE_APPS = ["Api", "QLearn", "QLink-react", "Video-payment-qs", "QLink", "Microservices"]
  RELEASE_STANDBY = 'standby'
  RELEASE_STARTED = 'started'
  RELASE_MESSAGE = ":thumbsup: All apps have been deployed to release branch! :reverse_thumbsup: \n_Please make sure all tests are passing and for release jobs before starting with the happy path_\n(`LEGACY:` https://jenkins.quipper.net/view/Releases/,\n`CURRENT:` https://jenkins.quipper.net/job/release-microservices/)"

  def send_time_to_slack
    HTTParty.post(settings.slack_incoming_url,
                  body: {
                    channel: settings.slack_channel,
                    username: settings.slack_username,
                    text: "_#{compute_time_in_english last_record}_",
                    icon_emoji: settings.slack_avatar
                  }.to_json,
                  headers: {'content-type' => 'application/json'}
                 )
  end

  def send_deploy_status_to_slack(release_data)
    HTTParty.post(settings.slack_incoming_url,
                  body: {
                    channel: settings.slack_channel,
                    username: settings.slack_username,
                    text: "#{deploy_status_in_english release_data}",
                    icon_emoji: settings.slack_avatar
                  }.to_json,
                  headers: {'content-type' => 'application/json'}
                 )
  end

  def deploy_status_in_english(app_status)
    deploy_status = "> Deploy status\n"
    deploy_status << app_status.map { | k, v | "#{k} #{v == 'true' ? ':white_check_mark:' : ':x:'}" }.join(" | ")
    if app_status.values.map { |state| state == "true" ? true : false }.reduce :&
      $redis.set('test_status', RELEASE_STARTED)
      deploy_status << "\n\n> #{RELASE_MESSAGE}"
    end

    deploy_status
  end

  def parse_time!(record)
    record.select { |key| !RELEASE_APPS.include? key }
      .each { | k, v | record[k] = Time.parse v }
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
