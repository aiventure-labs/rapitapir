# frozen_string_literal: true

require_relative '../../lib/rapitapir'

# Include DSL to use helper methods
include RapiTapir::DSL

# Define the same User API as before
user_api = [
  # Get all users
  RapiTapir.get('/users')
           .out(json_body([{ id: :integer, name: :string, email: :string, created_at: :datetime }]))
           .summary('Get all users')
           .description('Retrieve a paginated list of all users in the system'),

  # Get user by ID
  RapiTapir.get('/users/:id')
           .in(path_param(:id, :integer))
           .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime,
                            updated_at: :datetime }))
           .summary('Get user by ID')
           .description('Retrieve a specific user by their unique identifier'),

  # Create new user
  RapiTapir.post('/users')
           .in(body({ name: :string, email: :string, password: :string }))
           .out(json_body({ id: :integer, name: :string, email: :string, created_at: :datetime }))
           .summary('Create new user')
           .description('Create a new user account with the provided information'),

  # Update user
  RapiTapir.put('/users/:id')
           .in(path_param(:id, :integer))
           .in(body({ name: :string, email: :string }))
           .out(json_body({ id: :integer, name: :string, email: :string, updated_at: :datetime }))
           .summary('Update user')
           .description('Update an existing user\'s information'),

  # Delete user
  RapiTapir.delete('/users/:id')
           .in(path_param(:id, :integer))
           .out(json_body({ success: :boolean, message: :string }))
           .summary('Delete user')
           .description('Delete a user account permanently'),

  # Search users
  RapiTapir.get('/users/search')
           .in(query(:q, :string))
           .in(query(:limit, :integer, optional: true))
           .in(query(:offset, :integer, optional: true))
           .out(json_body({
                            users: [{ id: :integer, name: :string, email: :string }],
                            total: :integer,
                            limit: :integer,
                            offset: :integer
                          }))
           .summary('Search users')
           .description('Search for users by name or email with pagination support')
]

puts 'Generating documentation...'

# Generate Markdown documentation
puts "\n1. Generating Markdown documentation..."
markdown_generator = RapiTapir::Docs::MarkdownGenerator.new(
  endpoints: user_api,
  config: {
    title: 'User Management API',
    description: 'Complete API documentation for the User Management system',
    version: '2.0.0',
    base_url: 'https://api.example.com/v2',
    include_toc: true,
    include_examples: true
  }
)

markdown_file = File.join(__dir__, 'user-api-docs.md')
markdown_generator.save_to_file(markdown_file)

# Generate HTML documentation
puts "\n2. Generating HTML documentation..."
html_generator = RapiTapir::Docs::HtmlGenerator.new(
  endpoints: user_api,
  config: {
    title: 'User Management API',
    description: 'Interactive API documentation for the User Management system',
    version: '2.0.0',
    base_url: 'https://api.example.com/v2',
    theme: 'light',
    include_try_it: true
  }
)

html_file = File.join(__dir__, 'user-api-docs.html')
html_generator.save_to_file(html_file)

puts "\nDocumentation generated successfully!"
puts "\nFiles created:"
puts "- Markdown: #{markdown_file}"
puts "- HTML: #{html_file}"

puts "\nTo view the HTML documentation:"
puts "1. Open #{html_file} in your web browser"
puts '2. Or serve it with: python -m http.server 8000'
puts "3. Or use the CLI: ./bin/rapitapir serve --input #{__FILE__}"

puts "\nThe HTML documentation includes:"
puts "- Interactive 'Try it out' forms for each endpoint"
puts '- Syntax-highlighted code examples'
puts '- Responsive design for mobile and desktop'
puts '- Table of contents navigation'
puts '- Detailed parameter documentation'
