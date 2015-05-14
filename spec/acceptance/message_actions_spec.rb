require "spec_helper"

describe "Actions for Messages", :sqs do
  before do
    sqs.create_queue(queue_name: "test")
  end

  let(:queue_url) { sqs.list_queues(queue_name_prefix: "test").queue_urls.last }

  specify "SendMessage" do
    msg = "this is my message"
    result = sqs.send_message(queue_url: queue_url, message_body: msg)
    expect(result.md5_of_message_body).to eq(Digest::MD5.hexdigest(msg))
  end

  specify "ReceiveMessage" do
    body = "test 123"
    sqs.send_message(queue_url: queue_url, message_body: body)
    message = sqs.receive_message(queue_url: queue_url).messages.last
    expect(message.body).to eq(body)
  end

  specify "DeleteMessage" do
    sqs.send_message(queue_url: queue_url, message_body: "test")

    message1 = sqs.receive_message(queue_url: queue_url).messages.last
    sqs.delete_message(queue_url: queue_url, receipt_handle: message1.message_id)

    let_messages_in_flight_expire

    message2 = sqs.receive_message(queue_url: queue_url).messages.last
    expect(message2).to eq(nil)
  end

  specify "DeleteMessageBatch" do
    sqs.send_message(queue_url: queue_url, message_body: "test1")
    sqs.send_message(queue_url: queue_url, message_body: "test2")

    message1 = sqs.receive_message(queue_url: queue_url).messages.last
    message2 = sqs.receive_message(queue_url: queue_url).messages.last
    sqs.delete_message_batch(queue_url: queue_url, entries: [ { id: message1.message_id, receipt_handle: message1.message_id }, { id: message2.message_id, receipt_handle: message2.message_id } ])

    let_messages_in_flight_expire

    message3 = sqs.receive_message(queue_url: queue_url).messages.last
    expect(message3).to eq(nil)
  end

  specify "SendMessageBatch" do
    bodies = %w(a b c)
    sqs.send_message_batch(queue_url: queue_url, entries: [
      {
        id: SecureRandom.hex,
        message_body: 'a'
      },
      {
        id: SecureRandom.hex,
        message_body: 'b'
      },
      {
        id: SecureRandom.hex,
        message_body: 'c'
      }
    ])

    messages = sqs.receive_message(queue_url: queue_url, max_number_of_messages: 10).messages
    expect(messages.map(&:body)).to match_array(bodies)
  end

  specify "set message timeout to 0" do
    body = 'some-sample-message'
    sqs.send_message(queue_url: queue_url, message_body: body)
    message = sqs.receive_message(queue_url: queue_url).messages.last
    expect(message.body).to eq(body)

    sqs.change_message_visibility(queue_url: queue_url, receipt_handle: message.receipt_handle, visibility_timeout: 0)
    same_message = sqs.receive_message(queue_url: queue_url, visibility_timeout: 0).messages.last
    expect(same_message.body).to eq(body)
  end

  specify 'set message timeout and wait for message to come' do

    body = 'some-sample-message'
    sqs.send_message(queue_url: queue_url, message_body: body)
    message = sqs.receive_message(queue_url: queue_url).messages.last
    expect(message.body).to eq(body)
    sqs.change_message_visibility(queue_url: queue_url, receipt_handle: message.receipt_handle, visibility_timeout: 3)

    nothing = sqs.receive_message(queue_url: queue_url).messages.last
    expect(nothing).to eq(nil)

    sleep(10)

    same_message = sqs.receive_message(queue_url: queue_url).messages.last
    expect(same_message.body).to eq(body)
  end

  specify 'should fail if trying to update the visibility_timeout for a message that is not in flight' do
    body = 'some-sample-message'
    sqs.send_message(queue_url: queue_url, message_body: body)
    message = sqs.receive_message(queue_url: queue_url).messages.last
    expect(message.body).to eq(body)
    sqs.change_message_visibility(queue_url: queue_url, receipt_handle: message.receipt_handle, visibility_timeout: 0)

    expect do
      sqs.change_message_visibility(queue_url: queue_url, receipt_handle: message.receipt_handle, visibility_timeout: 30)
    end.to raise_error(Aws::SQS::Errors::MessageNotInflight)
  end

  def let_messages_in_flight_expire
    $fake_sqs.expire
  end
end
