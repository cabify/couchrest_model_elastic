require 'spec_helper'

describe CouchrestModelElastic::Client do

  let(:client) { described_class.new }
  let(:body) { {'couchdb' => {'param' => rand}} }
  let(:response) { {'ok' => 'maybe'} }

  it 'uses configured transport' do
    expect(client.client.transport).to be(test_transport)
  end

  it '#create generates correct request' do
    mock_client_response(:put, '/test_index/test_type/test_id?op_type=create') do |request_body|
      expect(request_body).to eq(body)
      [200, {}, response.to_json]
    end

    client.create('test_index', 'test_type', 'test_id', body)
    verify_mocked_responses
  end

  it '#create generates correct response' do
    mock_client_response(:put, '/test_index/test_type/test_id?op_type=create') do |request_body|
      [200, {}, response.to_json]
    end

    client_response = client.create('test_index', 'test_type', 'test_id', body)
    expect(client_response).to eq(response)
  end

  it '#index generates correct request' do
    mock_client_response(:put, '/test_index/test_type/test_id') do |request_body|
      expect(request_body).to eq(body)
      [200, {}, response.to_json]
    end

    client.index('test_index', 'test_type', 'test_id', body)
    verify_mocked_responses
  end

  it '#index generates correct response' do
    mock_client_response(:put, '/test_index/test_type/test_id') do |request_body|
      [200, {}, response.to_json]
    end

    client_response = client.index('test_index', 'test_type', 'test_id', body)
    expect(client_response).to eq(response)
  end

  it '#search generates correct request' do
    mock_client_response(:get, '/test_index/_search') do |request_body|
      expect(request_body).to eq(body)
      [200, {}, response.to_json]
    end

    client.search('test_index', nil, nil, body)
    verify_mocked_responses
  end

  it '#search generates correct response' do
    mock_client_response(:get, '/test_index/_search') do |request_body|
      [200, {}, response.to_json]
    end

    client_response = client.search('test_index', nil, nil, body)
    expect(client_response).to be_an_instance_of(CouchrestModelElastic::SearchResults)
  end
end