require 'spec_helper'

describe CouchrestModelElastic::River do
  let(:index_type) { 'TestModel' }
  let(:config) { {
    :couch_host => 'couch.host.com',
    :couch_port => '443',
    :couch_db => 'big_db',
    :couch_user => 'bigbird',
    :couch_password => 'topsecret',
    :couch_filter => 'Design/filter',
    :index => 'SomeIndex',
    :type => 'SomeType',
    :last_seq => rand(999999)
  } }
  let(:river) { described_class.new_with_defaults(index_type, config) }

  it 'updates with correct calls to client' do
    mock_client_response(:put, "/#{CouchrestModelElastic::River::RIVER_INDEX}/#{index_type}/#{CouchrestModelElastic::River::META_ID}") do |body|
      expect(body).to eq({
        'type' => CouchrestModelElastic::River::META_BODY_TYPE,
        'couchdb' => {
          'host' => config[:couch_host],
          'port' => config[:couch_port],
          'protocol' => 'https',
          'db' => config[:couch_db],
          'user' => config[:couch_user],
          'password' => config[:couch_password],
          'filter' => config[:couch_filter]
        },
        'index' => {
          'index' => config[:index],
          'type' => config[:type]
        }
      })
      [200, {}, '{}']
    end

    mock_client_response(:put, "/#{CouchrestModelElastic::River::RIVER_INDEX}/#{index_type}/#{CouchrestModelElastic::River::SEQ_ID}?op_type=create") do |body|
      expect(body).to eq({
        'couchdb' => {
          'last_seq' => config[:last_seq].to_s
        }
      })
      [200, {}, '{}']
    end

    river.update
    verify_mocked_responses
  end

  it '#fetch correctly instantiates river instance' do
    status = {'everything' => 'A OKAY'}
    mock_client_response(:get, "/#{CouchrestModelElastic::River::RIVER_INDEX}/#{index_type}/_search") do
      [200, {}, {'hits' => {'hits' => [
        {'_id' => CouchrestModelElastic::River::STATUS_ID, '_source' => status},
        {'_id' => CouchrestModelElastic::River::SEQ_ID, '_source' => {'couchdb' => {'last_seq' => config[:last_seq]}}},
        {'_id' => CouchrestModelElastic::River::META_ID, '_source' => {'couchdb' => {
          'host' => config[:couch_host],
          'port' => config[:couch_port],
          'filter' => config[:couch_filter],
          'db' => config[:couch_db],
        }}}
      ]}}.to_json]
    end

    river = described_class.fetch(index_type)
    expect(river.status).to eq(status)
    expect(river.last_seq).to eq(config[:last_seq])
    expect(river.config_index_type).to eq(index_type)
    expect(river.couch_db).to eq(config[:couch_db])
    expect(river.couch_host).to eq(config[:couch_host])
    expect(river.couch_port).to eq(config[:couch_port])
    expect(river.couch_filter).to eq(config[:couch_filter])
  end
end