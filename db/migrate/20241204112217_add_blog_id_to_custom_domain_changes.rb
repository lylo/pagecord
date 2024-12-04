class AddBlogIdToCustomDomainChanges < ActiveRecord::Migration[8.1]
  def change
    add_reference :custom_domain_changes, :blog, foreign_key: true

    CustomDomainChange.find_each do |change|
      change.update!(blog: change.user.blog)
    end

    change_column_null :custom_domain_changes, :blog_id, false

    remove_reference :custom_domain_changes, :user, foreign_key: true
  end
end
