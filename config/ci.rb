# Run using bin/ci

CI.run do
  group "Checks", parallel: 2 do
    step "Style: Ruby", "bin/rubocop"
    step "Security: Gem audit", "bundle exec bundle-audit check --update"
    step "Security: Importmap audit", "bin/importmap audit"
    step "Security: Brakeman", "bin/brakeman --quiet --no-pager --ensure-latest"

    group "Tests" do
      step "Tests: Rails", "bin/rails test"
      step "Tests: System", "bin/rails test:system"
    end
  end
end
