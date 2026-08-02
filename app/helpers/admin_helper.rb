module AdminHelper
  def blogs_date_column
    case params[:status]
    when "churning" then { label: "Churns on", sql: "MAX(subscriptions.next_billed_at)", order: :asc }
    when "paid" then { label: "Subscribed", sql: "MAX(subscriptions.created_at)" }
    else { label: "Created", sql: "blogs.created_at" }
    end
  end

  def custom_code_summary(blog)
    sizes = { head: blog.custom_head_html, body: blog.custom_body_html }
      .select { |_, code| code.present? }
      .map { |field, code| "#{field} #{number_to_human_size(code.bytesize)}" }

    return "None" if sizes.empty?

    safe_join([ sizes.to_sentence, blog.custom_code_active? ? nil : tag.span("off", class: "text-amber-600") ].compact, " · ")
  end
end
