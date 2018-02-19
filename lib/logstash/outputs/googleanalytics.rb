# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "digest/md5"
require "net/http"
require "erb"
include ERB::Util

# An googleanalytics output that does nothing.
class LogStash::Outputs::Googleanalytics < LogStash::Outputs::Base
  config_name "googleanalytics"
  concurrency :shared

  # Google analytics(GA) end point to sent hits
  # Change this to debug end point when testing.
  # https://www.google-analytics.com/debug/collect
  config :url, :validate => :string, :default => "https://www.google-analytics.com/batch"

  # GA measurement protocol version
  config :version, :validate => :string, :default => "1"

  # Your GA account's tracking id. This is required.
  config :tracking_id, :validate => :string, :required => true

  # The hit type the plugin should sent to GA.
  config :hit, :validate => ['pageview', 'screenview', 'event', 'transaction', 'item', 'social', 'exception', 'timing'], :default => "pageview"

  # The datasource the request is coming from.
  config :data_source, :validate => :string, :default => "logstash"

  # The field name which contains GA cookie.
  config :client_id, :validate => :string, :default => "ga"

  # The field name having client's ip address.
  config :client_ip, :validate => :string, :default => "clientip"

  # The field name which contains the full request path i.e. it must have host name and request path.
  config :full_path, :validate => :string

  # The field name which contains the request path.
  config :page_path, :validate => :string

  # The field name containing host name.
  config :host_name, :validate => :string

  # Custom dimension that will be sent with every request. The position of elements in array is used to determine the
  # custom dimension index. Make sure the custom dimensions are registered with GA first. More details on how to setup
  # check this link - https://support.google.com/analytics/answer/2709829.
  config :custom_dimension, :validate => :array, :default => ["ws"]

  # The field name containing user agent string.
  config :user_agent, :validate => :string, :default => "agent"

  # The field name containing referrer string.
  config :referrer, :validate => :string, :default => "referrer"

  # Give the hit a title here.
  config :title, :validate => :string, :default => "Webservice"

  public
  def register
    @logger.info("Googleanalytics: registering")
  end # def register

  public
  def multi_receive(events)
    body = []
    @logger.debug("Googleanalytics: Received #{events.size} events")

    # batch events into one request to GA
    events.each do |event|
      params = []
      client_id = event.get(@client_id)
      ip = event.get(@client_ip)
      user_agent = event.get(@user_agent)
      client_id = generate_client_id(client_id, ip, user_agent)

      # version
      params << "v=#{@version}"
      params << "tid=#{@tracking_id}"
      params << "t=#{@hit}"
      params << "ds=" + url_encode(event.sprintf(@data_source))
      params << "cid=" + url_encode(client_id)
      if !@full_path.nil? && !@full_path.empty?
        params << "dl=" + url_encode(event.get(@full_path))
      else
        params << "dp=" + url_encode(event.get(@page_path))
        params << "dh=" + url_encode(event.get(@host_name))
      end

      params << "dt=" + url_encode(@title)
      params << "dr=" + url_encode(event.get(@referrer))
      params << "uip=" + url_encode(ip)
      params << "ua=" + url_encode(user_agent)

      # custom dimension
      @custom_dimension.each_with_index do |value, index|
        params << "cd" + (index + 1).to_s + "=" + url_encode(value)
      end

      body << params.join('&')

    end

    payload = body.join("\n")
    @logger.debug("Googleanalytics: payload #{payload}")

    # sent request to GA
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/x-www-form-urlencoded ')
    request.body = payload
    res = http.request(request)
    @logger.debug("Googleanalytics: Successfully submitted to GA #{res.body}")

    return "Event received"
  end # def event

  # generate client id from cookie. If cookie not present generate id from ip address and user agent combined.
  def generate_client_id(cookie, ip, user_agent)
    if !( cookie.nil? || cookie.empty?)
      client_id = parse_client_id_from_cookie(cookie)
      if !client_id.nil?
        return client_id
      end
    end

    return generate_uuid(ip + user_agent)
  end

  # Generate UUID from string.
  def generate_uuid(message)
    md5 = Digest::MD5.new
    encoded_string = md5.hexdigest(message)
    uuid = encoded_string.unpack("m0").first.unpack("H8H4H4H4H12").join('-')
    @logger.debug("Googleanalytics: uuid generated #{uuid}")
    return uuid
  end

  # Parse analytics cookie snd extract client id
  def parse_client_id_from_cookie(cookie)
    parts = cookie.split('.')
    if(parts.size == 4 &&  parts[0] == 'GA1')
      return parts[2] + '.' + parts[3]
    end
  end
end # class LogStash::Outputs::Googleanalytics
