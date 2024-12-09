class Upvote < ApplicationRecord
  belongs_to :post, counter_cache: true, touch: true
end
