module Upvotable
  extend ActiveSupport::Concern

  included do
    has_many :upvotes, dependent: :destroy
  end
end
