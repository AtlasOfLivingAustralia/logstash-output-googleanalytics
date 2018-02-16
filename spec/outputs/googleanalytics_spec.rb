# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/googleanalytics"
require "logstash/codecs/plain"
require "logstash/event"

describe LogStash::Outputs::Googleanalytics do
  let(:sample_event) { LogStash::Event.new( "ga" => "",  "clientip" => "10.1.1.4", "agent" => "android" ) }
  let(:output) { LogStash::Outputs::Googleanalytics.new( "tracking_id" => "abc") }

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
end
