#!/usr/bin/env ruby
require_relative "../config/environment"

Blog.find_each do |blog|
  position = 1

  # Create PageNavigationItems from posts marked as navigation
  blog.pages.visible.where(show_in_navigation: true).order(:title).each do |page|
    PageNavigationItem.create!(
      blog: blog,
      post: page,
      label: page.display_title,
      position: position
    )
    position += 1
  end

  # Create SocialNavigationItems from social links
  blog.social_links.each do |social_link|
    SocialNavigationItem.create!(
      blog: blog,
      platform: social_link.platform,
      url: social_link.url,
      label: social_link.platform,
      position: position
    )
    position += 1
  end

  puts "Migrated #{position - 1} navigation items for blog #{blog.subdomain}"
end

puts "Migration complete!"
