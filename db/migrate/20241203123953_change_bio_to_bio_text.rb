class ChangeBioToBioText < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :bio, :bio_text

    User.find_each do |user|
      user.bio = user.bio_text&.gsub(/\n/, "<br>")
      user.save!
    end
  end
end
