# frozen_string_literal: true

require 'sinatra'
require_relative '../../lib/rapitapir'
require 'dotenv/load' # For loading environment variables

# Example Sinatra API with Auth0 OAuth2 integration
# Based on the Auth0 blog post patterns but using RapiTapir
class SongsAPIWithAuth0 < SinatraRapiTapir
  # Configure RapiTapir with OAuth2 authentication
  rapitapir do
    info(
      title: 'Songs API with Auth0',
      version: '1.0.0',
      description: 'A secure Sinatra API using Auth0 for authentication'
    )
    
    # Development defaults (CORS, health checks, etc.)
    development_defaults!
    
    # Enable documentation
    enable_docs
  end

  # Configure Auth0 OAuth2 authentication
  # Environment variables should be set:
  # AUTH0_DOMAIN=your-domain.auth0.com
  # AUTH0_AUDIENCE=https://your-api-identifier
  auth0_oauth2(
    domain: ENV['AUTH0_DOMAIN'],
    audience: ENV['AUTH0_AUDIENCE'],
    algorithm: 'RS256' # Auth0 default
  )
  
  puts "🔒 Configured Auth0 OAuth2: #{ENV['AUTH0_DOMAIN']}"

  # Manually include OAuth2 helper methods to ensure they're available
  helpers RapiTapir::Sinatra::OAuth2HelperMethods

  # Debug: Check what methods are available
  puts "🔍 Available methods: #{self.methods.grep(/oauth/).join(', ')}"

  # Protect endpoints that require authentication
  before '/songs' do
    # Only protect POST requests (creation)
    if request.post?
      authorize_oauth2!(required_scopes: ['write:tasks'])
    end
  end

  before '/songs/*' do
    # Protect PUT and DELETE requests (update/delete operations)
    if request.put?
      authorize_oauth2!(required_scopes: ['write:tasks'])
    elsif request.delete?
      authorize_oauth2!(required_scopes: ['admin:tasks'])
    end
  end

  # Song model (simple in-memory storage for demo)
  class Song
    attr_accessor :id, :name, :url

    def initialize(id, name, url)
      @id = id
      @name = name
      @url = url
    end

    def to_json(*_args)
      {
        'id' => id,
        'name' => name,
        'url' => url
      }.to_json
    end
  end

  # Sample data
  SONGS = [
    Song.new(1, 'My Way', 'https://www.last.fm/music/Frank+Sinatra/_/My+Way'),
    Song.new(2, 'Strangers in the Night', 'https://www.last.fm/music/Frank+Sinatra/_/Strangers+in+the+Night'),
    Song.new(3, 'Fly Me to the Moon', 'https://www.last.fm/music/Frank+Sinatra/_/Fly+Me+to+the+Moon')
  ]

  # Define schemas using RapiTapir's type system
  SONG_SCHEMA = T.hash({
    'id' => T.integer(minimum: 1),
    'name' => T.string(min_length: 1, max_length: 200),
    'url' => T.string(format: :url)
  })

  CREATE_SONG_SCHEMA = T.hash({
    'name' => T.string(min_length: 1, max_length: 200),
    'url' => T.string(format: :url)
  })

  ERROR_SCHEMA = T.hash({
    'error' => T.string,
    'error_description' => T.optional(T.string)
  })

  # Public endpoints (no authentication required)

  # GET /songs - List all songs (public)
  endpoint(
    GET('/songs')
      .summary('List all songs')
      .description('Retrieve a list of all Frank Sinatra songs')
      .ok(T.array(SONG_SCHEMA))
      .tags('songs')
      .build
  ) do
    SONGS.to_json
  end

  # GET /songs/:id - Get song by ID (public)
  endpoint(
    GET('/songs/:id')
      .summary('Get song by ID')
      .description('Retrieve a specific song by its ID')
      .path_param(:id, T.integer(minimum: 1))
      .ok(SONG_SCHEMA)
      .error_response(404, ERROR_SCHEMA, description: 'Song not found')
      .tags('songs')
      .build
  ) do |inputs|
    song = SONGS.find { |s| s.id == inputs[:id] }
    
    unless song
      halt 404, { 
        error: 'not_found',
        error_description: 'Song not found' 
      }.to_json
    end

    song.to_json
  end

  # Protected endpoints (OAuth2 authentication required)

  # POST /songs - Create new song (requires authentication)
  endpoint(
    POST('/songs')
      .summary('Create a new song')
      .description('Create a new song entry (requires authentication)')
      .body(CREATE_SONG_SCHEMA)
      .created(SONG_SCHEMA)
      .error_response(400, ERROR_SCHEMA, description: 'Invalid input')
      .error_response(401, ERROR_SCHEMA, description: 'Authentication required')
      .error_response(403, ERROR_SCHEMA, description: 'Insufficient permissions')
      .tags('songs')
      .build
  ) do |inputs|
    # Authentication handled by before filter
    
    # Extract body data from inputs
    body_data = inputs[:body]
    
    # Create new song
    new_id = SONGS.map(&:id).max + 1
    new_song = Song.new(new_id, body_data['name'], body_data['url'])
    
    # Add to our in-memory store
    SONGS << new_song
    
    new_song.to_json
  end

  # PUT /songs/:id - Update song (requires authentication)
  endpoint(
    PUT('/songs/:id')
      .summary('Update a song')
      .description('Update an existing song (requires authentication)')
      .path_param(:id, T.integer(minimum: 1))
      .body(CREATE_SONG_SCHEMA)
      .ok(SONG_SCHEMA)
      .error_response(400, ERROR_SCHEMA, description: 'Invalid input')
      .error_response(401, ERROR_SCHEMA, description: 'Authentication required')
      .error_response(403, ERROR_SCHEMA, description: 'Insufficient permissions')
      .error_response(404, ERROR_SCHEMA, description: 'Song not found')
      .tags('songs')
      .build
  ) do |inputs|
    # Authentication handled by before filter
    
    song = SONGS.find { |s| s.id == inputs[:id] }
    
    unless song
      halt 404, { 
        error: 'not_found',
        error_description: 'Song not found' 
      }.to_json
    end

    # Extract body data from inputs
    body_data = inputs[:body]
    
    # Update song properties
    song.name = body_data['name'] if body_data['name']
    song.url = body_data['url'] if body_data['url']
    
    song.to_json
  end

  # DELETE /songs/:id - Delete song (requires authentication with admin scope)
  endpoint(
    DELETE('/songs/:id')
      .summary('Delete a song')
      .description('Delete a song (requires admin permissions)')
      .path_param(:id, T.integer(minimum: 1))
      .ok(SONG_SCHEMA)
      .error_response(401, ERROR_SCHEMA, description: 'Authentication required')
      .error_response(403, ERROR_SCHEMA, description: 'Admin permissions required')
      .error_response(404, ERROR_SCHEMA, description: 'Song not found')
      .tags('songs')
      .build
  ) do |inputs|
    # Authentication handled by before filter
    
    song = SONGS.find { |s| s.id == inputs[:id] }
    
    unless song
      halt 404, { 
        error: 'not_found',
        error_description: 'Song not found' 
      }.to_json
    end

    # In a real app, you'd delete from database
    # For demo, we'll remove from array and return the song
    SONGS.delete(song)
    song.to_json
  end

  # GET /me - Get current user info (requires authentication)
  # Using regular Sinatra route since RapiTapir endpoints have different context
  get '/me' do
    # Authenticate user
    context = authorize_oauth2!
    
    content_type :json
    {
      user: context.user,
      scopes: context.scopes,
      token_info: {
        issuer: context.metadata[:issuer],
        subject: context.metadata[:subject],
        audience: context.metadata[:audience],
        expires_at: context.metadata[:expires_at]&.iso8601
      }
    }.to_json
  end

  # Error handlers
  error RapiTapir::Auth::InvalidTokenError do
    {
      error: 'invalid_token',
      error_description: env['sinatra.error'].message
    }.to_json
  end

  error RapiTapir::Auth::AuthenticationError do
    {
      error: 'authentication_failed',
      error_description: env['sinatra.error'].message
    }.to_json
  end

  # Helper methods for testing and demonstrations
  helpers do
    # Method to generate a test token (for development/testing only)
    def generate_test_instructions
      {
        message: 'To test protected endpoints, you need a valid Auth0 access token',
        instructions: [
          '1. Set up your Auth0 application and API',
          '2. Get an access token using the Auth0 Dashboard test feature',
          '3. Send requests with: Authorization: Bearer YOUR_TOKEN',
          '4. Ensure your token has the required scopes'
        ],
        required_scopes: {
          'create:songs' => 'Required to create new songs',
          'update:songs' => 'Required to update existing songs',
          'delete:songs' => 'Required to delete songs',
          'admin' => 'Required for administrative operations'
        },
        example_curl: 'curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:4567/me'
      }
    end
  end

  # Development helper endpoint (remove in production)
  get '/auth-info' do
    content_type :json
    generate_test_instructions.to_json
  end
end

# Run the application if this file is executed directly
if __FILE__ == $0
  # Ensure required environment variables are set
  required_env_vars = %w[AUTH0_DOMAIN AUTH0_AUDIENCE]
  missing_vars = required_env_vars.reject { |var| ENV[var] }
  
  if missing_vars.any?
    puts "❌ Missing required environment variables: #{missing_vars.join(', ')}"
    puts "\n📝 Create a .env file with:"
    puts "AUTH0_DOMAIN=your-domain.auth0.com"
    puts "AUTH0_AUDIENCE=https://your-api-identifier"
    exit 1
  end

  puts "🚀 Starting Songs API with Auth0 OAuth2..."
  puts "📖 Documentation available at: http://localhost:4567/docs"
  puts "🔍 Auth info available at: http://localhost:4567/auth-info"
  puts "🎵 Public songs endpoint: http://localhost:4567/songs"
  
  SongsAPIWithAuth0.run!
end
