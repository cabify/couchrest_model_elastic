require 'spec_helper'

describe CouchrestModelElastic::NamedSearches do
  let(:index) { 'someIndex' }
  let(:type) { 'aType' }
  let(:named_searches) { described_class.new { |i| i.index = index; i.type = type } }

  it 'uses type & index to construct the search' do
    index, type = 'Abcd', 'Efgy'
    named_searches.index = index
    named_searches.type = type

    mock_client_response(:get, "/#{index}/#{type}/_search")
    named_searches.search
    verify_mocked_responses
  end

  it 'uses query from named search definition when searching' do
    match_value = 'forty'
    mock_client_response(:get, "/#{index}/#{type}/_search") do |body|
      expect(body).to eq({'some_filter' => {'match' => match_value}})
      [200, {}, '{}']
    end
    named_searches.named_search(:test) { |q, match| q.some_filter { q.set!(:match, match) } }

    named_searches.call(:test, match_value)
    verify_mocked_responses
  end

  it 'applies the result mapper' do
    id = 1234
    named_searches.result_source_mapper = ->(source) { {:other_id => (source['id'] * 2)} }
    mock_client_response(:get, "/#{index}/#{type}/_search") do
      [200, {}, {'hits' => {'hits' => [{'_source' => {'id' => id}}]}}.to_json]
    end

    results = named_searches.search
    expect(results[0].source).to eq({:other_id => id * 2})
  end

  it 'allows iteration over names of searches' do
    searches = [:test1, :test2]
    searches.each do |search_name|
      named_searches.named_search(search_name)
    end
    expect { |b| named_searches.each(&b) }.to yield_successive_args(*searches)
  end

  it '#extend_with_named_searches adds search methods to given object' do
    ShouldBeSearchable = Module.new
    named_searches.named_search(:test_should_be_method)

    described_class.extend_with_named_searches(ShouldBeSearchable, named_searches, :base_search_name)
    expect(ShouldBeSearchable.respond_to?(:test_should_be_method)).to be_true
    expect(ShouldBeSearchable.respond_to?(:base_search_name)).to be_true
    expect(ShouldBeSearchable.base_search_name).to be(named_searches)
  end

end