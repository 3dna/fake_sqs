require "aws-sdk"
require "fake_sqs/test_integration"

Aws.config = {
  region:            "us-east-1",
  access_key_id:     "fake access key",
  secret_access_key: "fake secret key",
}

db = ENV["SQS_DATABASE"] || ":memory:"
puts "\n\e[34mRunning specs with database \e[33m#{db}\e[0m"
$fake_sqs = FakeSQS::TestIntegration.new(database: db, sqs_endpoint: "localhost", sqs_port: 4568)

module SpecHelper
  def sqs
    Aws::SQS::Client.new(endpoint: "http://localhost:4568")
  end
end

RSpec.configure do |config|
  config.before(:each, :sqs) { $fake_sqs.start }
  config.before(:each, :sqs) { $fake_sqs.reset }
  config.after(:suite) { $fake_sqs.stop }
  config.include SpecHelper
end
