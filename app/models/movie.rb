class Movie < ApplicationRecord
  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end

  def self.find_in_tmdb(search_params, api_key = ENV['TMDB_API_KEY'])
    # Allow backward compatibility if a raw URL string is passed in early specs
    if search_params.is_a?(String)
      return Faraday.get(search_params)
    end

    base_url = 'https://api.themoviedb.org/3/search/movie'
    query_params = {
      api_key: api_key,
      query: search_params[:title]
    }
    query_params[:year] = search_params[:release_year] if search_params[:release_year].present?
    query_params[:language] = 'en-US' if search_params[:language] == 'en'

    response = Faraday.get(base_url, query_params)
    parsed = JSON.parse(response.body)

    return [] if parsed['results'].blank?

    parsed['results'].map do |movie_data|
      Movie.new(
        title: movie_data['title'],
        release_date: movie_data['release_date'],
        rating: 'R'
      )
    end
  end
end