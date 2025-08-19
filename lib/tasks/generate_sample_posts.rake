namespace :posts do
  desc "Generate sample blog posts for testing"
  task :generate_samples, [:blog_subdomain, :count] => :environment do |task, args|
    blog_subdomain = args[:blog_subdomain] || "joel"
    post_count = (args[:count] || 100).to_i
    
    # Find the blog
    blog = Blog.find_by(subdomain: blog_subdomain)
    if blog.nil?
      puts "❌ Blog with subdomain '#{blog_subdomain}' not found"
      exit 1
    end
    
    puts "Found blog: #{blog.subdomain} with #{blog.posts.count} existing posts"
    
    # Sample data arrays
    titles = [
      "The Future of Web Development",
      "Understanding Ruby on Rails Performance", 
      "10 Tips for Better Code Reviews",
      "Database Optimization Strategies",
      "Building Scalable Applications",
      "The Art of Clean Code",
      "Modern JavaScript Frameworks Compared",
      "Debugging Like a Pro",
      "API Design Best Practices",
      "Security in Web Applications",
      "Test-Driven Development Benefits",
      "Microservices vs Monoliths",
      "DevOps Culture and Practices",
      "User Experience Design Principles",
      "Machine Learning for Developers",
      "Cloud Computing Essentials",
      "Version Control Best Practices",
      "Performance Monitoring Tools",
      "Agile Development Methodologies",
      "Full-Stack Development Guide"
    ]
    
    content_paragraphs = [
      "In today's rapidly evolving tech landscape, staying up-to-date with the latest trends and best practices is crucial for success.",
      "Performance optimization is not just about making things faster - it's about creating better user experiences and reducing operational costs.",
      "When working with large codebases, maintainability becomes one of the most important factors to consider in your development process.",
      "Database design decisions made early in a project can have lasting impacts on scalability and performance down the road.",
      "Clean code isn't just about following style guides - it's about writing code that communicates intent clearly to other developers.",
      "Testing is an investment in the future stability and reliability of your application, not just a checkbox to tick.",
      "Modern development practices emphasize collaboration, continuous learning, and adapting to changing requirements quickly.",
      "Security should be built into the development process from the beginning, not added as an afterthought.",
      "Understanding your users' needs and pain points is essential for building products that truly solve problems.",
      "The best solutions often come from understanding the problem deeply rather than jumping straight to implementation."
    ]
    
    # Valid tags without special characters
    tags_pool = [
      "ruby", "rails", "javascript", "performance", "database", "security", "testing", 
      "devops", "api", "frontend", "backend", "fullstack", "mobile", "web", "cloud",
      "docker", "microservices", "agile", "tdd", "design", "ux", "algorithms",
      "optimization", "monitoring", "deployment", "cicd", "graphql", "rest"
    ]
    
    # Calculate how many posts to create
    current_count = blog.posts.count
    posts_to_create = [post_count - current_count, 0].max
    
    if posts_to_create == 0
      puts "✅ Blog already has #{current_count} posts (target: #{post_count})"
      exit 0
    end
    
    puts "Creating #{posts_to_create} additional posts..."
    
    posts_to_create.times do |i|
      # Random title
      title = "#{titles.sample} #{current_count + i + 1}"
      
      # Random rich text content (2-4 paragraphs)
      num_paragraphs = rand(2..4)
      content_html = "<div>"
      num_paragraphs.times do
        content_html += "<p>#{content_paragraphs.sample}</p>"
      end
      content_html += "</div>"
      
      # Random tags (1-4 tags)
      num_tags = rand(1..4)
      selected_tags = tags_pool.sample(num_tags)
      
      # Random published date in the past 6 months
      published_at = rand(6.months.ago..Time.current)
      
      begin
        blog.posts.create!(
          title: title,
          content: content_html,
          tag_list: selected_tags,
          status: :published,
          published_at: published_at
        )
        
        print "."
        if (i + 1) % 10 == 0
          puts " #{i + 1} posts created"
        end
      rescue => e
        puts "\n❌ Error creating post #{i + 1}: #{e.message}"
        break
      end
    end
    
    puts "\n✅ Final counts:"
    puts "Total posts: #{blog.posts.reload.count}"
    puts "Published posts: #{blog.posts.published.count}"
    puts "Draft posts: #{blog.posts.draft.count}"
  end
end