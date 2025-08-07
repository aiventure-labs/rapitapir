# frozen_string_literal: true

require 'bundler/setup'

# Add the project root to the load path for development
project_root = File.expand_path('../../', __dir__)
$LOAD_PATH.unshift(File.join(project_root, 'lib')) unless $LOAD_PATH.include?(File.join(project_root, 'lib'))

require 'rapitapir'
require 'rapitapir/ai/llm_instruction'
require 'json'

# Type alias for convenience (avoid warning if already defined)
T = RapiTapir::Types unless defined?(T)

module UserValidationAPI
  # User creation validation schema
  USER_INPUT_SCHEMA = T.hash({
    'name' => T.string(min_length: 2, max_length: 50),
    'email' => T.email,
    'age' => T.integer(minimum: 18, maximum: 120),
    'preferences' => T.optional(T.hash({
      'newsletter' => T.boolean,
      'notifications' => T.boolean
    }))
  }).freeze

  USER_OUTPUT_SCHEMA = T.hash({
    'id' => T.integer,
    'name' => T.string,
    'email' => T.string,
    'status' => T.string,
    'created_at' => T.datetime
  }).freeze

  VALIDATION_ERROR_SCHEMA = T.hash({
    'error' => T.string,
    'field_errors' => T.array(T.hash({
      'field' => T.string,
      'message' => T.string,
      'code' => T.string
    }))
  }).freeze

  # Data transformation schemas
  LEGACY_USER_INPUT = T.hash({
    'full_name' => T.string,
    'email_address' => T.string,
    'birth_year' => T.integer,
    'settings' => T.optional(T.string) # JSON string in legacy format
  }).freeze

  # Analytics schema
  USER_ANALYTICS_SCHEMA = T.hash({
    'user_count' => T.integer,
    'active_users' => T.integer,
    'signup_rate' => T.float,
    'demographics' => T.hash({
      'avg_age' => T.float,
      'age_distribution' => T.array(T.hash({
        'range' => T.string,
        'count' => T.integer
      }))
    })
  }).freeze

  # Validation endpoint with LLM instruction for input validation
  CREATE_USER = RapiTapir.post('/users')
    .json_body(USER_INPUT_SCHEMA)
    .ok(USER_OUTPUT_SCHEMA)
    .error_out(400, VALIDATION_ERROR_SCHEMA)
    .llm_instruction(
      purpose: :validation,
      fields: [:body] # Focus on request body validation
    )
    .summary('Create a new user with validation')
    .description('Creates a new user account with comprehensive input validation and business rule checking')
    .mcp_export

  # Transformation endpoint for legacy data migration
  MIGRATE_LEGACY_USER = RapiTapir.post('/users/migrate')
    .json_body(LEGACY_USER_INPUT)
    .ok(USER_OUTPUT_SCHEMA)
    .llm_instruction(
      purpose: :transformation,
      fields: :all
    )
    .summary('Migrate legacy user data to new format')
    .description('Transforms legacy user data format to current schema with proper field mapping')
    .mcp_export

  # Analysis endpoint for user analytics
  USER_ANALYTICS = RapiTapir.get('/users/analytics')
    .query(:start_date, :date)
    .query(:end_date, :date) 
    .query(:segment, T.optional(T.string))
    .ok(USER_ANALYTICS_SCHEMA)
    .llm_instruction(
      purpose: :analysis,
      fields: [:json] # Focus on analyzing the response data
    )
    .summary('Get user analytics and insights')
    .description('Provides comprehensive user analytics including demographics and engagement metrics')
    .mcp_export

  # Documentation endpoint for API reference
  USER_SEARCH = RapiTapir.get('/users/search')
    .query(:q, T.string(min_length: 1))
    .query(:limit, T.optional(T.integer(minimum: 1, maximum: 100)))
    .query(:offset, T.optional(T.integer(minimum: 0)))
    .ok(T.hash({
      'users' => T.array(USER_OUTPUT_SCHEMA),
      'total_count' => T.integer,
      'has_more' => T.boolean
    }))
    .llm_instruction(
      purpose: :documentation,
      fields: :all
    )
    .summary('Search for users')
    .description('Full-text search across user profiles with pagination support')
    .mcp_export

  # Testing endpoint for comprehensive test generation
  UPDATE_USER = RapiTapir.put('/users/:id')
    .path_param(:id, :integer)
    .json_body(T.hash({
      'name' => T.optional(T.string(min_length: 2, max_length: 50)),
      'email' => T.optional(T.email),
      'preferences' => T.optional(T.hash({
        'newsletter' => T.boolean,
        'notifications' => T.boolean
      }))
    }))
    .ok(USER_OUTPUT_SCHEMA)
    .error_out(404, T.hash({'error' => T.string}))
    .error_out(400, VALIDATION_ERROR_SCHEMA)
    .llm_instruction(
      purpose: :testing,
      fields: :all
    )
    .summary('Update user information')
    .description('Updates user profile with partial data and validation')
    .mcp_export

  # Completion endpoint for smart field suggestions
  USER_PROFILE_COMPLETION = RapiTapir.post('/users/complete')
    .json_body(T.hash({
      'partial_profile' => T.hash({
        'name' => T.optional(T.string),
        'email' => T.optional(T.string),
        'location' => T.optional(T.string),
        'interests' => T.optional(T.array(T.string))
      })
    }))
    .ok(T.hash({
      'suggestions' => T.hash({
        'name' => T.optional(T.array(T.string)),
        'email' => T.optional(T.string),
        'location' => T.optional(T.array(T.string)),
        'interests' => T.optional(T.array(T.string))
      }),
      'confidence_scores' => T.hash({
        'name' => T.optional(T.float),
        'email' => T.optional(T.float),
        'location' => T.optional(T.float),
        'interests' => T.optional(T.float)
      })
    }))
    .llm_instruction(
      purpose: :completion,
      fields: [:body]
    )
    .summary('Get smart profile completion suggestions')
    .description('Provides intelligent suggestions for completing user profile data')
    .mcp_export
end

# Endpoints for CLI
user_validation_api = [
  UserValidationAPI::CREATE_USER,
  UserValidationAPI::MIGRATE_LEGACY_USER,
  UserValidationAPI::USER_ANALYTICS,
  UserValidationAPI::USER_SEARCH,
  UserValidationAPI::UPDATE_USER,
  UserValidationAPI::USER_PROFILE_COMPLETION
]
