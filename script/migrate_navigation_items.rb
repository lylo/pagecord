#!/usr/bin/env ruby
require_relative "../config/environment"

Blog.find_each do |blog|
  position = 1

  # Create PageNavigationItems from posts marked as navigation
  blog.pages.visible.where(show_in_navigation: true).order(:title).each do |page|
    begin
      PageNavigationItem.create!(
        blog: blog,
        post: page,
        label: page.display_title,
        position: position
      )
      position += 1
    rescue Exception => e
      puts "Failed to create Nav item for Page #{page.token} on blog #{blog.subdomain}"
      puts e
    end
  end

  # Create SocialNavigationItems from social links
  blog.social_links.each do |social_link|
    begin
      SocialNavigationItem.create!(
        blog: blog,
        platform: social_link.platform,
        url: social_link.url,
        label: social_link.platform,
        position: position
      )
      position += 1
    rescue Exception => e
      puts "Failed to migrate SocialLink #{social_link.id} for blog #{blog.subdomain}"
      puts e
    end
  end

  puts "Migrated #{position - 1} navigation items for blog #{blog.subdomain}"
end

puts "Migration complete!"
