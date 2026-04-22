class ContactMailerPreview < ActionMailer::Preview
  def new_message
    blog = Blog.first
    contact_message = Blog::ContactMessage.new(blog: blog, name: "Jane Doe", email: "jane@example.com", message: "Hey! I love your blog. Would you be open to collaborating on a post together?")
    ContactMailer.with(contact_message: contact_message).new_message
  end
end
