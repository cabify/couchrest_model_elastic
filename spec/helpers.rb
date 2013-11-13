module Helpers
  def load_data(data_file_name)
    File.read(File.join(File.dirname(__FILE__), 'data', data_file_name))
  end

  def mock_client_response(http_method, *stub_args, &expectation)
    test_transport_stubs.public_send(http_method, *stub_args) do |env|
      expectation ? expectation.call(JSON.parse(env[:body]), env) : [200, {}, '{}']
    end
  end

  def verify_mocked_responses
    test_transport_stubs.verify_stubbed_calls
  end

  def test_transport_stubs
    @test_transport_stubs ||= Faraday::Adapter::Test::Stubs.new
  end

  def test_transport
    @test_transport ||= Elasticsearch::Transport::Transport::HTTP::Faraday.new(hosts: [{host: 'test.host', port: '0'}]) do |faraday_config|
      faraday_config.adapter :test, self.test_transport_stubs
    end
  end
end