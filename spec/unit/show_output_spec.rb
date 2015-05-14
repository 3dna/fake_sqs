require 'fake_sqs/show_output'
require 'rack/mock'

describe FakeSQS::ShowOutput do
  after do
    $stdout = STDOUT
  end

  it "outputs the result of rack app" do
    app = double :app
    $stdout = StringIO.new
    middleware = FakeSQS::ShowOutput.new(app)
    env = Rack::MockRequest.env_for("/")
    expect(app).to receive(:call).with(env).and_return([200, {}, ["<xml>"]])

    middleware.call(env)

    $stdout.rewind
    expect($stdout.read).to eq("--- {}\n\n<xml>\n")
  end
end
