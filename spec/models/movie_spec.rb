require 'rails_helper'
require 'spec_helper'

describe Movie do
  describe 'searching TMDB by keyword' do
    it 'calls Faraday gem' do
      response = double('response', body: '{"results":[]}', status: 200, success?: true)
      expect(Faraday).to receive(:get).and_return(response)
      Movie.find_in_tmdb({ title: 'hacker', language: 'en' })
    end

    it 'raises an API error when TMDb rejects the request' do
      diagnostics = {}
      response = double(
        'response',
        body: '{"status_code":7,"status_message":"Invalid API key"}',
        status: 401,
        success?: false
      )
      expect(Faraday).to receive(:get).and_return(response)

      expect do
        Movie.find_in_tmdb({ title: 'hacker', language: 'en' }, diagnostics: diagnostics)
      end.to raise_error(Movie::TmdbApiError, /HTTP 401/)
      expect(diagnostics).to include(status: 'error', http_status: 401, api_code: 7)
    end

    it 'calls TMDb with valid API key and returns unsaved Movie objects' do
      diagnostics = {}
      results = Movie.find_in_tmdb(
        { title: 'Olympics', release_year: '2000', language: 'en' },
        diagnostics: diagnostics
      )
      expect(results.length).to eq(2)
      expect(results.first).to be_a(Movie)
      expect(results.first.new_record?).to be true
      expect(results.first.rating).to eq('R')
      expect(diagnostics).to include(status: 'success', http_status: 200, result_count: 2)
    end
  end
end