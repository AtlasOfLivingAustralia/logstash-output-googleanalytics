# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/googleanalytics"
require "logstash/codecs/plain"
require "logstash/event"

describe LogStash::Outputs::Googleanalytics do
  let(:sample_event) { LogStash::Event.new( "ga" => "",  "clientip" => "10.1.1.4", "agent" => "android", "dl" => "http://www.ala.org.au/ws/1.txt" ) }
  let(:output) { LogStash::Outputs::Googleanalytics.new( "tracking_id" => "abc", "url" => "https://www.google-analytics.com/debug/collect", "full_path" => "dl") }

  before do
    output.register
  end

  describe "multi receive message" do
    subject { output.multi_receive([sample_event]) }

    it "returns a string" do
      expect(subject).to eq("Event received")
    end
  end

  describe "UUID generation from message" do
    subject { output.generate_uuid("10.1.1.4android") }

    it "returns a string" do
      expect(subject).to eq("6fcdfcd5-a7db-d74e-1b71-df1af5f6dbef")
    end
  end

  describe "Parsing Universal analytics cookie" do
    subject { output.parse_client_id_from_cookie("GA1.2.299259584.1357814039257") }

    it "returns client id" do
      expect(subject).to eq("299259584.1357814039257")
    end
  end

  describe "When cookie is not present" do
    subject { output.generate_client_id("", "10.1.1.4", "android") }

    it "returns uuid v4" do
      expect(subject).to eq("6fcdfcd5-a7db-d74e-1b71-df1af5f6dbef")
    end
  end
end
