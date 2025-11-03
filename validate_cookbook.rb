#!/usr/bin/env ruby

# Simple cookbook validation script
require 'json'

puts "🔍 Validating time-cookbook structure..."

# Check required files
required_files = [
  'metadata.rb',
  'recipes/default.rb',
  'attributes/default.rb'
]

missing_files = []
required_files.each do |file|
  unless File.exist?(file)
    missing_files << file
  end
end

if missing_files.empty?
  puts "✅ All required cookbook files present"
else
  puts "❌ Missing required files: #{missing_files.join(', ')}"
  exit 1
end

# Check recipes directory
recipes = Dir.glob('recipes/*.rb')
puts "📝 Found #{recipes.length} recipes:"
recipes.each { |recipe| puts "   - #{File.basename(recipe, '.rb')}" }

# Check templates
templates = Dir.glob('templates/**/*.erb')
puts "📄 Found #{templates.length} templates:"
templates.each { |template| puts "   - #{template}" }

# Check tests
tests = Dir.glob('test/**/*_test.rb')
puts "🧪 Found #{tests.length} integration tests:"
tests.each { |test| puts "   - #{test}" }

# Load and validate metadata
begin
  load 'metadata.rb'
  puts "✅ metadata.rb loaded successfully"
rescue => e
  puts "❌ Error loading metadata.rb: #{e.message}"
  exit 1
end

puts "\n🎉 Cookbook validation completed successfully!"
puts "\nNext steps for testing:"
puts "1. Upload to Chef Automate or Chef Server"
puts "2. Apply to test nodes with appropriate attributes"
puts "3. Verify NTP and timezone configuration"

puts "\nSample node attributes:"
puts JSON.pretty_generate({
  "time" => {
    "timezone" => "America/New_York",
    "ntp_servers" => [
      "0.pool.ntp.org",
      "1.pool.ntp.org"
    ]
  }
})