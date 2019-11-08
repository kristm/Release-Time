require 'httparty'
require 'time'
require 'date'

module Helpers
  RELEASE_APPS = ["Microservices"]
  RELEASE_STANDBY = 'standby'
  RELEASE_STARTED = 'started'
  RELEASE_MESSAGE = ":thumbsup: Microservices has been deployed to release branch! :reverse_thumbsup: \n_Please make sure all tests are passing before starting with the happy path_\n(https://jenkins.quipper.net/job/release-microservices/)"
  HOLIDAY_TEMPLATE = "<!here|here> Next Monday, %{monday} is *%{holiday}* holiday in Japan. :jp: Next week's Global release will start on %{tuesday} (Tuesday). :calendar:"
  JP_HOLIDAYS_URL ="https://holidays-jp.github.io/api/v1/date.json"

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

  def send_jp_holiday_notification_to_slack
    jp_holiday = jp_holiday_on_monday

    return unless jp_holiday
    message = HOLIDAY_TEMPLATE % jp_holiday

    HTTParty.post(settings.slack_incoming_url,
                  body: {
                    channel: settings.slack_channel,
                    username: settings.slack_username,
                    text: message,
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
      deploy_status << "\n\n> #{RELEASE_MESSAGE}"
    end

    deploy_status
  end

  def parse_time!(record)
    record.select { |key| key[/^(start|stop)$/] }
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

  def date_next_monday
    # 0 = Sunday, 1 = Monday, 2 = Monday
    date_today = Date.today
    days_until_monday = (1 - date_today.wday) % 7
    date_today + days_until_monday
  end

  def jp_holiday_on_monday
    jp_holidays = HTTParty.get(JP_HOLIDAYS_URL).parsed_response

    formatted_monday = date_next_monday.strftime("%Y-%m-%d")
    holiday = jp_holidays[formatted_monday]

    if holiday
      formatted_tuesday = (date_next_monday + 1).strftime("%Y-%m-%d")
      {
        monday: formatted_monday,
        tuesday: formatted_tuesday,
        holiday: holiday
      }
    end
  end
end
