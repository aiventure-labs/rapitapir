# Using RapiTapir APIs as LLM Tools (MCP)

RapiTapir supports the Model Context Protocol (MCP) to make your API endpoints discoverable and consumable by LLMs and AI agents.

### How to Mark Endpoints for MCP Export

Use the `.mcp_export` method in your endpoint DSL chain:

```ruby
endpoint = RapiTapir.get('/hello')
  .in(query(:name, :string))
  .out(json_body(:message => :string))
  .mcp_export
```

### CLI Usage

Generate MCP context using the command line:

```bash
# Generate MCP context for all marked endpoints
rapitapir generate mcp --endpoints api.rb --output mcp-context.json

# Alternative export command
rapitapir export mcp --endpoints api.rb --output mcp-context.json
```

### Ruby API Usage

Use the MCP exporter directly in Ruby code:

```ruby
require 'rapitapir/ai/mcp'

# Load your endpoints
endpoints = [your_endpoint_list]

# Create exporter and generate context
exporter = RapiTapir::AI::MCP::Exporter.new(endpoints)
mcp_context = exporter.as_mcp_context

# Save to file
File.write('mcp-context.json', JSON.pretty_generate(mcp_context))
```

### Example Output

The generated MCP context includes:

```json
{
  "name": "RapiTapir API Context",
  "version": "1.0.0",
  "endpoints": [
    {
      "name": "get__users__id_",
      "method": "GET", 
      "path": "/users/{id}",
      "summary": "Retrieve a user by ID",
      "description": "Fetches a single user record by their unique identifier",
      "input_schema": {
        "id": {
          "type": "integer",
          "kind": "path",
          "required": true
        }
      },
      "output_schema": {
        "json": {
          "type": {
            "id": "integer",
            "name": "string",
            "email": "string"
          }
        }
      },
      "examples": []
    }
  ]
}
```

### Use Cases
- LLM/agent tool discovery
- Automated API documentation for AI
- Integration with agent frameworks (LangChain, OpenAI, etc.)

See the AI integration plan for more details.
