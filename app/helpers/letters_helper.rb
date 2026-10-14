module LettersHelper
  # period: adds a full stop that's hidden on phones, where each blank gets its own line.
  def letter_blank(form, method, label:, as: :text_field, size: nil, lead: nil, trail: nil, period: false, **options)
    tag.span class: "letter-field" do
      safe_join [
        ("#{lead} " if lead),
        form.label(method, label, class: "sr-only"),
        form.public_send(as, method, class: class_names("letter-blank", "letter-blank--#{size}" => size), **options),
        (tag.span(trail) if trail),
        (tag.span(".", class: "letter-trail") if period)
      ].compact
    end
  end

  def letter_subdomain_blank(form, **options)
    letter_blank form, :subdomain, label: "Subdomain", size: :subdomain, trail: ".pagecord.com.",
      placeholder: "subdomain", maxlength: Subdomain::MAX_LENGTH, required: true, autocapitalize: "none", spellcheck: false, **options
  end

  def letter_email_blank(form, **options)
    letter_blank form, :email, label: "Email", as: :email_field, size: :email, period: true,
      placeholder: "your email", required: true, autocomplete: "email", **options
  end
end
