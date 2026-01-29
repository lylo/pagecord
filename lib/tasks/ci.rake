desc "Run the CI pipeline locally (brakeman, rubocop, importmap audit, tests)"
task ci: :environment do
  steps = [
    { name: "Brakeman", cmd: "bundle exec brakeman --quiet --no-pager" },
    { name: "Rubocop", cmd: "bundle exec rubocop" },
    { name: "Importmap Audit", cmd: "bin/importmap audit" },
    { name: "Unit Tests", cmd: "bin/rails test" },
    { name: "System Tests", cmd: "bin/rails test:system" }
  ]

  results = []

  steps.each do |step|
    puts "\n#{"=" * 60}"
    puts "Running: #{step[:name]}"
    puts "=" * 60

    success = system(step[:cmd])
    results << { name: step[:name], passed: success }

    unless success
      puts "\n#{step[:name]} failed!"
      break
    end
  end

  puts "\n#{"=" * 60}"
  puts "CI Summary"
  puts "=" * 60
  results.each do |r|
    status = r[:passed] ? "✅ Passed" : "❌ Failed"
    puts "#{r[:name].ljust(20)} #{status}"
  end

  exit 1 if results.any? { |r| !r[:passed] }
  puts "\nAll checks passed!"
end
