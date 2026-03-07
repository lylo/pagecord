module Post::Filterable
  extend ActiveSupport::Concern

  class_methods do
    def apply_filters(tag: nil, without_tag: nil, title: nil, emailed: nil, lang: nil, blog_locale: nil)
      scope = all
      scope = scope.tagged_with_any(*Array(tag)) if tag
      scope = scope.tagged_without_any(*Array(without_tag)) if without_tag
      scope = scope.where.not(title: [ nil, "" ]) if title.to_s == "true"
      scope = scope.where(title: [ nil, "" ]) if title.to_s == "false"
      scope = scope.emailed if emailed.to_s == "true"
      scope = scope.not_emailed if emailed.to_s == "false"
      scope = scope.for_locale(lang, blog_locale) if lang
      scope
    end

    def for_locale(lang, blog_locale)
      locale = lang.to_s.downcase.split("-").first
      blog_locale == locale ? where(locale: [ locale, nil ]) : where(locale: locale)
    end
  end
end
