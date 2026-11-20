require 'rails_helper'

describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    before :each do
      @fake_results = [double('movie1'), double('movie2')]
    end

    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).with('hardware').
        and_return(@fake_results)
      get :search_tmdb, params: { search_terms: 'hardware' }
    end

    describe 'after valid search' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
        get :search_tmdb, params: { search_terms: 'hardware' }
      end

      it 'selects the Search Results template for rendering' do
        expect(response).to render_template('search_tmdb')
      end

      it 'makes the TMDb search results available to that template' do
        expect(assigns(:movies)).to eq(@fake_results)
      end
    end

    it 'flashes a warning if title is missing' do
      get :search_tmdb, params: { title: '' }
      expect(flash[:warning]).to eq('Please fill in all required fields!')
    end

    it 'flashes a warning if the title is omitted from a search' do
      get :search_tmdb, params: { release_year: '2000' }
      expect(flash[:warning]).to eq('Please fill in all required fields!')
    end

    it 'flashes a warning when the search returns no movies' do
      allow(Movie).to receive(:find_in_tmdb).and_return([])
      get :search_tmdb, params: { title: 'No matching movie' }
      expect(flash[:warning]).to eq('No movies found with given parameters!')
    end
  end

  describe 'adding a movie from TMDb' do
    it 'creates a new movie and redirects to search page' do
      expect {
        post :add_movie, params: { title: 'Manhunter', release_date: '1986-08-15', rating: 'R' }
      }.to change(Movie, :count).by(1)
      expect(flash[:notice]).to eq('Manhunter was successfully added to RottenPotatoes.')
      expect(response).to redirect_to(search_tmdb_path)
    end
  end


end