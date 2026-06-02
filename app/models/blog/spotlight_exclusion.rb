class Blog::SpotlightExclusion < ApplicationRecord
  belongs_to :blog, touch: true
end
