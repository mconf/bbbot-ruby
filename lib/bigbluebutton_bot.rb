class BigBlueButtonBot
  BOT_FILENAME = "../extras/bbbot.jar"
  LOG_FILENAME = "../extras/log4j.properties"
  LOG_DEBUG_FILENAME = "../extras/log4j.debug.properties"
  @@pids = []

  # Starts the bot. Wait until the meeting is started (will check for it using the BBB API)
  # or until the timeout expires.
  # api::      BigBlueButtonApi object to access the server. See the gem bigbluebutton-api-ruby.
  # meeting::  ID of the meeting that the bot should join
  # count::    Number of bots to start
  # timeout::  Maximum time waiting for the meeting to be started (in secs).
  def initialize(api, meeting, salt="", count=1, timeout=20)
    server = parse_server_url(api.url)

    # note: fork + exec with these parameters was the only solution found to run the command in background
    # and be able to wait for it (kill it) later on (see BigBlueButtonBot.finalize)
    pid = Process.fork do
      bot_file = File.join(File.dirname(__FILE__), BOT_FILENAME)
      if ENV['DEBUG']
        log_file = File.join(File.dirname(__FILE__), LOG_DEBUG_FILENAME)
      else
        log_file = File.join(File.dirname(__FILE__), LOG_FILENAME)
      end

      command = ["java",
                 "-Dlog4j.configuration=file:#{log_file}",
                 "-jar", "#{bot_file}",
                 "--single_meeting", "true",
                 "--server", "#{server}",
                 "--key", "#{salt}",
                 "--meeting", "#{meeting}",
                 "--numbots", "#{count}"]
      logger(command.join(" "))
      exec(*command)

      # other options that didn't work:
      # IO::popen("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # exec(["java", "-jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null"])
      # exec("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # Process.exit!
    end
    @@pids << [meeting, pid]

    wait_bot_startup(api, meeting, count, timeout)
  end

  # Kill the processes running the bots
  def self.finalize(meeting=nil)
    @@pids.each do |this_meeting, pid|
      if meeting.nil? or this_meeting == meeting
        Process.kill("TERM", pid)
        Process.detach(pid)
      end
    end
    if meeting.nil?
      @@pids.clear
    else
      @@pids.delete_if{ |this_meeting, pid| this_meeting == meeting }
    end
  end

  protected

  # Receives the server URL, possibly with a path and/or parameters: e.g. http://server.com/bigbluebutton/api
  # Returns only the protocol + domain, as used in the bot initialization: e.g. http://server.com
  def parse_server_url(full_url)
    uri = URI.parse(full_url)
    uri_s = uri.scheme + "://" + uri.host
    uri_s = uri_s + ":" + uri.port.to_s if uri.port != uri.default_port
    uri_s
  end

  # Wait until the meeting is running with a certain number of participants
  # api::          The BigBlueButtonApi object
  # meeting::      The ID of the meeting
  # participants:: Number of participants that should be in the meeting
  # timeout::      Maximum wait time in seconds
  def wait_bot_startup(api, meeting, participants, timeout=20)
    Timeout::timeout(timeout) do
      logger("waiting for meeting #{meeting} with #{participants} participants")
      stop_wait = false
      while !stop_wait
        sleep 1

        # find the meeting and hope it is running
        response = api.get_meetings
        logger("response from getMeetings: #{response.inspect}")
        selected = response[:meetings].reject!{ |m| m[:meetingID] != meeting }
        if selected and selected.size > 0
          logger("found the target meeting!")

          # check how many participants are in the meeting
          pass = selected[0][:moderatorPW]
          response = api.get_meeting_info(meeting, pass)
          logger("response from getMeetingInfo: #{response.inspect}")
          stop_wait = response[:participantCount] >= participants
          logger("was the number of participants reached? #{stop_wait}")
        end
      end
    end
  end

  def logger(msg)
    puts "BigBlueButtonBot: #{msg}" if ENV['DEBUG']
  end
end
