require "loops_sdk"

LoopsSdk.configure do |config|
  config.api_key = ENV["LOOPS_API_KEY"]
end
