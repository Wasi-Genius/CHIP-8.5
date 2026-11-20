require 'rails_helper'
require 'spec_helper'

describe Movie do
  describe 'searching TMDB by keyword' do
    it 'calls Faraday gem' do
      expect(Faraday).to receive(:get).and_return(double('response', body: '{"results":[]}'))
      Movie.find_in_tmdb({ title: 'hacker', language: 'en' })
    end

    it 'calls TMDb with valid API key and returns unsaved Movie objects' do
      results = Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000', language: 'en' })
      expect(results.length).to eq(2)
      expect(results.first).to be_a(Movie)
      expect(results.first.new_record?).to be true
      expect(results.first.rating).to eq('R')
    end
  end
end