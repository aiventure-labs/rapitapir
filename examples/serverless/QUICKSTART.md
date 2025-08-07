# 🚀 Quick Start: Deploy RapiTapir to Serverless

This guide will get you from zero to a deployed serverless API in under 5 minutes.

## ⚡ 30-Second Deploy

1. **Choose your platform** and copy the appropriate example:
   ```bash
   # AWS Lambda
   cp aws_lambda_example.rb my_api.rb
   
   # Google Cloud Functions  
   cp gcp_cloud_functions_example.rb my_api.rb
   
   # Azure Functions
   cp azure_functions_example.rb my_api.rb
   
   # Vercel Edge
   cp vercel_example.rb my_api.rb
   ```

2. **Deploy with one command**:
   ```bash
   # Automated deployment
   ./deploy.rb --platform aws --name my-api
   
   # Or manually for AWS
   sam build && sam deploy
   
   # Or manually for Vercel
   vercel --prod
   ```

3. **Test your API**:
   ```bash
   curl "https://your-function-url/health"
   curl "https://your-function-url/books"
   ```

## 🎯 Platform Comparison

| Feature | AWS Lambda | Google Cloud Functions | Azure Functions | Vercel Edge |
|---------|------------|----------------------|-----------------|-------------|
| **Cold Start** | 200ms | 300ms | 400ms | 50ms |
| **Free Tier** | 1M requests | 2M requests | 1M requests | 100GB-h |
| **Max Memory** | 10GB | 8GB | 1.5GB | 512MB |
| **Max Duration** | 15min | 9min | 10min | 30s |
| **Best For** | Enterprise | AI/ML | Microsoft stack | Frontend |

## 🔧 Customization Examples

### Add Authentication

```ruby
class SecureServerlessAPI < SinatraRapiTapir
  rapitapir do
    info(title: 'Secure API', version: '1.0.0')
    bearer_auth :jwt
  end

  endpoint(
    GET('/protected')
      .bearer_auth(scopes: ['api:read'])
      .ok(T.hash({ "data" => T.string }))
      .build
  ) { { data: "Secret information" } }
end
```

### Add Database Integration

```ruby
# AWS with DynamoDB
endpoint(GET('/users/:id').build) do |inputs|
  dynamodb.get_item(
    table_name: 'users',
    key: { id: inputs[:id] }
  ).item
end

# GCP with Firestore
endpoint(GET('/users/:id').build) do |inputs|
  firestore = Google::Cloud::Firestore.new
  doc = firestore.doc("users/#{inputs[:id]}").get
  doc.data
end
```

### Add AI Features

```ruby
endpoint(
  POST('/ai/analyze')
    .body(T.hash({ "text" => T.string }))
    .enable_llm_instructions(purpose: :analysis)
    .enable_rag
    .build
) do |inputs|
  # AI-powered text analysis
  result = AI.analyze(inputs[:body][:text], context: rag_context)
  { analysis: result }
end
```

## 🛠️ Development Workflow

### 1. Local Development

```bash
# Install dependencies
bundle install

# Run locally
ruby aws_lambda_example.rb
# or
functions-framework-ruby --target=rapitapir_book_api
# or  
func start
# or
vercel dev
```

### 2. Testing

```bash
# Run tests
bundle exec rspec

# Test specific platform
bundle exec rspec spec/aws_lambda_spec.rb
```

### 3. Deployment

```bash
# Deploy to specific platform
./deploy.rb --platform vercel --name my-api

# Deploy to all platforms
./deploy.rb --platform all --name my-api

# Dry run (see commands without executing)
./deploy.rb --platform aws --dry-run
```

## 📊 Monitoring & Debugging

### Platform-Specific Monitoring

**AWS Lambda:**
```bash
# View logs
aws logs tail /aws/lambda/my-function --follow

# View metrics
aws cloudwatch get-metric-statistics --namespace AWS/Lambda
```

**Google Cloud Functions:**
```bash
# View logs  
gcloud functions logs read my-function --limit 50

# View metrics
gcloud logging read "resource.type=cloud_function"
```

**Azure Functions:**
```bash
# View logs
func azure functionapp logstream my-function-app

# View in portal
az functionapp show --name my-function-app
```

**Vercel:**
```bash
# View logs
vercel logs my-deployment-url

# View analytics
vercel inspect my-deployment-url
```

## 🔒 Security Best Practices

### Environment Variables

```bash
# AWS
aws lambda update-function-configuration \
  --function-name my-function \
  --environment Variables='{API_KEY=secret}'

# GCP
gcloud functions deploy my-function \
  --set-env-vars API_KEY=secret

# Azure
az functionapp config appsettings set \
  --name my-function-app \
  --settings API_KEY=secret

# Vercel
vercel env add API_KEY
```

### Input Validation

```ruby
# RapiTapir provides automatic validation
endpoint(
  POST('/users')
    .body(T.hash({
      "email" => T.email,              # Validates email format
      "age" => T.integer(minimum: 18), # Validates age >= 18
      "name" => T.string(min_length: 2) # Validates min length
    }))
    .build
) do |inputs|
  # inputs[:body] is guaranteed to be valid
  User.create(inputs[:body])
end
```

## 🎭 Common Patterns

### Pattern 1: API Gateway

Single function handling multiple endpoints (recommended for most use cases):

```
Function: my-api
├── GET /health
├── GET /books
├── POST /books
└── GET /books/:id
```

### Pattern 2: Microservices

Separate functions for different domains:

```
Function: users-api     → /api/users/*
Function: books-api     → /api/books/*  
Function: orders-api    → /api/orders/*
```

### Pattern 3: Edge + Origin

Fast edge responses with backend fallback:

```
Edge (Vercel)    → Fast reads, cached data
Origin (AWS)     → Complex operations, database writes
```

## 🚨 Troubleshooting

### Common Issues

**Cold Start Too Slow:**
```ruby
# Use smaller dependencies
gem 'rapitapir', require: ['rapitapir/core'] # Only core features

# Pre-warm connections
configure do
  database_pool = ConnectionPool.new { Database.connect }
  set :database, database_pool
end
```

**Memory Limit Exceeded:**
```ruby
# Optimize memory usage
configure do
  set :static, false    # Disable static files
  set :sessions, false  # Disable sessions
end

# Use streaming for large responses
endpoint(GET('/large-data').build) do
  stream do |out|
    LargeDataset.find_each { |record| out << record.to_json + "\n" }
  end
end
```

**Timeout Errors:**
```ruby
# Set appropriate timeouts
endpoint(GET('/slow-operation').build) do
  # Use async processing for long operations
  job_id = SlowJobService.enqueue(params)
  { job_id: job_id, status: 'processing' }
end
```

### Debug Mode

```ruby
class DebugServerlessAPI < SinatraRapiTapir
  configure do
    set :logging, true
    set :show_exceptions, true if development?
  end

  before do
    logger.info "Request: #{request.request_method} #{request.path_info}"
    logger.info "Headers: #{request.env.select { |k,v| k.start_with?('HTTP_') }}"
  end
end
```

## 🎉 You're Ready!

You now have everything you need to deploy production-ready RapiTapir APIs to any serverless platform. Choose your platform, customize the example, and deploy with confidence!

### Next Steps

1. **Explore the examples** in this directory
2. **Read the [comprehensive README](README.md)** for advanced features
3. **Check out [RapiTapir docs](../../README.md)** for the full DSL reference
4. **Join the community** and share your serverless APIs!

---

**Happy deploying! 🚀**
