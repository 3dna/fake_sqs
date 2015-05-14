require "spec_helper"

describe "Actions for Queues", :sqs do
  specify "CreateQueue" do
    queue = sqs.create_queue(queue_name: "test-create-queue")
    queue_attributes = sqs.get_queue_attributes(queue_url: queue.queue_url)
    expect(queue.queue_url).to eq("http://0.0.0.0:4568/test-create-queue")
    expect(queue_attributes.attributes["QueueArn"]).to match(%r"arn:aws:sqs:us-east-1:.+:test-create-queue")
  end

  specify "GetQueueUrl" do
    sqs.create_queue(queue_name: "test-get-queue-url")
    queue_url = sqs.list_queues(queue_name_prefix: "test-get-queue-url").queue_urls.last
    expect(queue_url).to eq("http://0.0.0.0:4568/test-get-queue-url")
  end

  specify "ListQueues" do
    sqs.create_queue(queue_name: "test-list-1")
    sqs.create_queue(queue_name: "test-list-2")
    expect(sqs.list_queues.queue_urls).to eq [
      "http://0.0.0.0:4568/test-list-1",
      "http://0.0.0.0:4568/test-list-2"
    ]
  end

  specify "ListQueues with prefix" do
    sqs.create_queue(queue_name: "test-list-1")
    sqs.create_queue(queue_name: "test-list-2")
    sqs.create_queue(queue_name: "other-list-3")
    expect(sqs.list_queues(queue_name_prefix: "test").queue_urls).to eq [
      "http://0.0.0.0:4568/test-list-1",
      "http://0.0.0.0:4568/test-list-2",
    ]
  end

  specify "DeleteQueue" do
    sqs.create_queue(queue_name: "test-delete")
    queue_url = sqs.list_queues(queue_name_prefix: "test-delete").queue_urls.last

    expect(sqs.list_queues.queue_urls.count).to eq(1)
    sqs.delete_queue(queue_url: queue_url)
    expect(sqs.list_queues.queue_urls.count).to eq(0)
  end

  specify "SetQueueAttributes / GetQueueAttributes" do
    queue_url = sqs.create_queue(queue_name: "my-queue").queue_url
    sqs.set_queue_attributes(queue_url: queue_url, attributes: { "MaximumMessageSize" => "262144" })

    queue_attributes = sqs.get_queue_attributes(queue_url: queue_url)
    expect(queue_attributes.attributes["MaximumMessageSize"]).to eq("262144")
  end
end
