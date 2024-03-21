class PostsMailbox < ApplicationMailbox
  def process
    recipient = mail.to.first.downcase
    from = mail.from.first.downcase

    Rails.logger.info "Received mail from: #{from} to: #{recipient}"

    if user = User.find_by(email: from, delivery_email: recipient)
      Rails.logger.info "Creating post from user: #{user.id}"

      body = MailParser.new(mail).body
      user.posts.create!(title: mail.subject, content: body)
    end
  end
end
