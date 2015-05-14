require 'fake_sqs/responder'
require 'active_support/core_ext/hash'
require 'verbose_hash_fetch'

describe FakeSQS::Responder do
  it "yields xml" do
    xml = subject.call :GetQueueUrl do |xml|
      xml.QueueUrl "example.com"
    end

    data = Hash.from_xml(xml)
    url = data.
      fetch("GetQueueUrlResponse").
      fetch("GetQueueUrlResult").
      fetch("QueueUrl")
    expect(url).to eq("example.com")
  end

  it "skips result if no block is given" do
    xml = subject.call :DeleteQueue

    data = Hash.from_xml(xml)

    response = data.fetch("DeleteQueueResponse")
    expect(response.keys.include?("ResponseMetadata")).to eq(true)
    expect(response.keys.include?("DeleteQueueResponse")).to eq(false)
  end

  it "has metadata" do
    xml = subject.call(:GetQueueUrl) do |xml|
    end

    data = Hash.from_xml(xml)

    request_id = data.
      fetch("GetQueueUrlResponse").
      fetch("ResponseMetadata").
      fetch("RequestId")

    expect(request_id.length).to eq(36)
  end
end
