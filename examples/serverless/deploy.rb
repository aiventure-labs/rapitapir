#!/usr/bin/env ruby
# frozen_string_literal: true

# RapiTapir Serverless Deployment Helper
# This script helps deploy RapiTapir APIs to various serverless platforms

require 'optparse'
require 'json'
require 'fileutils'

class ServerlessDeployer
  PLATFORMS = %w[aws gcp azure vercel all].freeze
  
  def initialize
    @options = {}
    parse_options
  end

  def run
    case @options[:platform]
    when 'aws'
      deploy_aws
    when 'gcp'
      deploy_gcp
    when 'azure'
      deploy_azure
    when 'vercel'
      deploy_vercel
    when 'all'
      deploy_all
    else
      puts "Error: Invalid platform. Use: #{PLATFORMS.join(', ')}"
      exit 1
    end
  end

  private

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      
      opts.on('-p', '--platform PLATFORM', PLATFORMS, 
              'Platform to deploy to (aws, gcp, azure, vercel, all)') do |platform|
        @options[:platform] = platform
      end
      
      opts.on('-n', '--name NAME', 'Function/API name') do |name|
        @options[:name] = name
      end
      
      opts.on('-r', '--region REGION', 'Deployment region') do |region|
        @options[:region] = region
      end
      
      opts.on('--dry-run', 'Show commands without executing') do
        @options[:dry_run] = true
      end
      
      opts.on('-h', '--help', 'Show this help') do
        puts opts
        exit
      end
    end.parse!
    
    if @options[:platform].nil?
      puts "Error: Platform is required. Use -p to specify."
      exit 1
    end
    
    @options[:name] ||= 'rapitapir-api'
    @options[:region] ||= 'us-east-1'
  end

  def deploy_aws
    puts "🚀 Deploying to AWS Lambda..."
    
    commands = [
      'bundle install --deployment',
      'sam build',
      "sam deploy --stack-name #{@options[:name]} --region #{@options[:region]} --capabilities CAPABILITY_IAM --confirm-changeset"
    ]
    
    execute_commands(commands)
    
    puts "✅ AWS Lambda deployment complete!"
    puts "📝 Check AWS Console for function URL"
  end

  def deploy_gcp
    puts "🚀 Deploying to Google Cloud Functions..."
    
    commands = [
      'bundle install',
      "gcloud functions deploy #{@options[:name]} --runtime ruby32 --trigger-http --allow-unauthenticated --region #{@options[:region]}"
    ]
    
    execute_commands(commands)
    
    puts "✅ Google Cloud Functions deployment complete!"
    puts "📝 Function URL: https://#{@options[:region]}-PROJECT-ID.cloudfunctions.net/#{@options[:name]}"
  end

  def deploy_azure
    puts "🚀 Deploying to Azure Functions..."
    
    commands = [
      'bundle install',
      'func init --worker-runtime custom',
      "func azure functionapp create #{@options[:name]} --consumption-plan-location #{@options[:region]}",
      "func azure functionapp publish #{@options[:name]}"
    ]
    
    execute_commands(commands)
    
    puts "✅ Azure Functions deployment complete!"
    puts "📝 Check Azure Portal for function URL"
  end

  def deploy_vercel
    puts "🚀 Deploying to Vercel..."
    
    # Check if vercel.json exists
    unless File.exist?('vercel.json')
      puts "⚠️  Creating vercel.json configuration..."
      create_vercel_config
    end
    
    commands = [
      'bundle install',
      'vercel --prod'
    ]
    
    execute_commands(commands)
    
    puts "✅ Vercel deployment complete!"
    puts "📝 Your API is live at the URL shown above"
  end

  def deploy_all
    puts "🚀 Deploying to all platforms..."
    
    %w[aws gcp azure vercel].each do |platform|
      puts "\n" + "="*50
      @options[:platform] = platform
      send("deploy_#{platform}")
    end
    
    puts "\n" + "="*50
    puts "✅ All deployments complete!"
  end

  def execute_commands(commands)
    commands.each do |command|
      puts "$ #{command}"
      
      if @options[:dry_run]
        puts "  (dry run - not executed)"
      else
        success = system(command)
        unless success
          puts "❌ Command failed: #{command}"
          exit 1
        end
      end
    end
  end

  def create_vercel_config
    config = {
      version: 2,
      name: @options[:name],
      builds: [
        {
          src: "*.rb",
          use: "@vercel/ruby"
        }
      ],
      routes: [
        {
          src: "/(.*)",
          dest: "/vercel_example.rb"
        }
      ]
    }
    
    File.write('vercel.json', JSON.pretty_generate(config))
    puts "📝 Created vercel.json"
  end
end

# Run if called directly
if __FILE__ == $0
  begin
    deployer = ServerlessDeployer.new
    deployer.run
  rescue Interrupt
    puts "\n❌ Deployment cancelled"
    exit 1
  rescue => e
    puts "❌ Error: #{e.message}"
    exit 1
  end
end
