class AddGoogleSiteVerificationToBlogs < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :google_site_verification, :string
  end
end
