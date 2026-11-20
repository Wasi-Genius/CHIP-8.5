class Movie < ApplicationRecord
  class TmdbApiError < StandardError; end

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

  def self.find_in_tmdb(search_params, api_key = ENV['TMDB_API_KEY'], diagnostics: nil)
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

    Rails.logger.info(
      "TMDb search request (api_key_configured=#{api_key.present?}, " \
      "release_year_present=#{search_params[:release_year].present?}, " \
      "language=#{search_params[:language] == 'en' ? 'en' : 'all'})"
    )

    begin
      response = Faraday.get(base_url, query_params)
    rescue Faraday::Error => error
      diagnostics&.merge!(
        status: 'error',
        error_type: error.class.name,
        message: 'TMDb connection failed'
      )
      Rails.logger.error("TMDb connection failed (#{error.class})")
      raise TmdbApiError, "TMDb connection failed (#{error.class})"
    end

    begin
      parsed = JSON.parse(response.body)
    rescue JSON::ParserError
      diagnostics&.merge!(
        status: 'error',
        http_status: response.status,
        message: 'TMDb returned invalid JSON'
      )
      Rails.logger.error("TMDb returned invalid JSON (HTTP #{response.status})")
      raise TmdbApiError, "TMDb returned invalid JSON (HTTP #{response.status})"
    end

    unless parsed.is_a?(Hash)
      diagnostics&.merge!(
        status: 'error',
        http_status: response.status,
        message: 'TMDb returned an unexpected response'
      )
      Rails.logger.error("TMDb returned an unexpected response shape (HTTP #{response.status})")
      raise TmdbApiError, "TMDb returned an unexpected response (HTTP #{response.status})"
    end

    unless response.success?
      api_code = parsed['status_code']
      api_message = parsed['status_message'].to_s.gsub(/[\r\n]/, ' ')[0, 200]
      diagnostics&.merge!(
        status: 'error',
        http_status: response.status,
        api_code: api_code,
        message: api_message
      )
      Rails.logger.error(
        "TMDb API error (http_status=#{response.status}, " \
        "api_code=#{api_code.inspect}, message=#{api_message.inspect})"
      )
      raise TmdbApiError, "TMDb returned HTTP #{response.status} (API code #{api_code.inspect})"
    end

    results = parsed['results']
    unless results.is_a?(Array)
      diagnostics&.merge!(
        status: 'error',
        http_status: response.status,
        message: 'TMDb response did not contain a results array'
      )
      Rails.logger.error("TMDb response did not contain a results array (HTTP #{response.status})")
      raise TmdbApiError, "TMDb returned an unexpected response (HTTP #{response.status})"
    end

    diagnostics&.merge!(
      status: 'success',
      http_status: response.status,
      result_count: results.length
    )
    Rails.logger.info(
      "TMDb search response (http_status=#{response.status}, result_count=#{results.length})"
    )
    return [] if results.empty?

    results.map do |movie_data|
      Movie.new(
        title: movie_data['title'],
        release_date: movie_data['release_date'],
        rating: 'R'
      )
    end
  end
end