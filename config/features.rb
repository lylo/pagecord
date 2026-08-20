env "FEATURE"

# Gates who can put a password on a blog. Enforcement is deliberately not
# gated: a blog with a password stays private whatever this returns, so
# turning the flag off can never expose one that's already locked.
feature :private_blogs do |user: nil, blog: nil|
  user&.features&.include?("private_blogs")
end
