require 'fake_sqs/message'

describe FakeSQS::Message do
  describe "#body" do
    it "is extracted from the MessageBody" do
      message = create_message("MessageBody" => "abc")
      expect(message.body).to eq("abc")
    end
  end

  describe "#md5" do
    it "is calculated from body" do
      message = create_message("MessageBody" => "abc")
      expect(message.md5).to eq("900150983cd24fb0d6963f7d28e17f72")
    end
  end

  describe "#id" do
    it "is generated" do
      message = create_message
      expect(message.id.length).to eq(36)
    end
  end

  describe "#attributes" do
    it "is defaulted" do
      message = create_message
      expect(message.attributes["SenderId"]).not_to be_nil
      expect(message.attributes["SentTimestamp"].to_i).to be >= Time.now.to_i
      expect(message.attributes["ApproximateReceiveCount"]).to eq(0)
      expect(message.attributes["ApproximateFirstReceiveTimestamp"]).to be >= Time.now.to_i
    end

    it "can be overriden" do
      message = create_message("Attributes" => {"SenderId" => "foobar", "custom" => "values"})
      expect(message.attributes["SenderId"]).to eq "foobar"
      expect(message.attributes["custom"]).to eq("values")
    end
  end

  describe 'visibility_timeout' do
    let :message do
      create_message
    end

    it 'should default to nil' do
      expect(message.visibility_timeout).to eq(nil)
    end

    it 'should be expired when it is nil' do
      expect(message.expired?).to eq(true)
    end

    it 'should be expired if set to a previous time' do
      message.visibility_timeout = Time.now - 1
      expect(message.expired?).to eq(true)
    end

    it 'should not be expired at a future date' do
      message.visibility_timeout = Time.now + 1
      expect(message.expired?).to eq(false)
    end

    it 'should not be expired when set to expire at a future date' do
      message.expire_at(5)
      expect(message.visibility_timeout >= Time.now + 4).to eq(true)
    end
  end

  def create_message(options = {})
    FakeSQS::Message.new({"MessageBody" => "test"}.merge(options))
  end
end
