class Post < ApplicationRecord
  belongs_to :user, dependent: :destroy
end
