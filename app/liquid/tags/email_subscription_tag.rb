module Tags
  class EmailSubscriptionTag < Liquid::Tag
    def render(context)
      view = context.registers[:view]
      view.render(partial: "blogs/email_subscriber_form")
    end
  end
end
