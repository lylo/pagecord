class AddIndexToCustomDomainChangesBlogId < ActiveRecord::Migration[8.2]
  def change
    # The only foreign key in the schema without an index. blog.custom_domain_changes
    # and the dependent: :destroy on Blog were both sequential scans.
    add_index :custom_domain_changes, :blog_id
  end
end
