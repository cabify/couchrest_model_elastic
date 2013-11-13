require 'json'
require 'spec_helper'

describe CouchrestModelElastic::SearchResults do
  let(:source_mapper) { nil }
  let(:results) { described_class.new(JSON.parse(load_data('search_response.json')), &source_mapper) }
  let(:expected_results) {
    [
      described_class::Result.new({'id' => 'A', 'role' => 'public', 'type' => 'Client'}, 'couchindex', 'Client', 'abc', 2.0),
      described_class::Result.new({'id' => 'B', 'role' => 'private', 'type' => 'Client'}, 'couchindex', 'Client', 'def', 1.0),
      described_class::Result.new({'id' => 'C', 'role' => 'test', 'type' => 'Client'}, 'couchindex', 'Client', 'geh', 1.0),
    ]
  }

  it 'correctly parses hits meta data' do
    expect(results.total).to eq(500)
    expect(results.count).to eq(3)
    expect(results.max_score).to eq(1.0)
  end

  it 'allows iteration over results' do
    expect { |b| results.each(&b) }.to yield_successive_args(*expected_results)
  end

  it 'allows #[] access to results' do
    expect(results[1]).to eq(expected_results[1])
  end

  describe 'source mapper' do
    SomeSource = Struct.new(:role)
    let(:source_mapper) { ->(source) { SomeSource.new(source['role']) } }

    it 'applies source_mapper' do
      expect(results[0].source).to eq(SomeSource.new('public'))
    end
  end
end