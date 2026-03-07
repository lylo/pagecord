module Post::Filterable
  extend ActiveSupport::Concern

  class_methods do
    def filtered_for_dynamic_variable(tag: nil, without_tag: nil, title: nil, emailed: nil, lang: nil, blog_locale: nil, year: nil, sort: nil)
      apply_filters(
        tag: tag,
        without_tag: without_tag,
        title: title,
        emailed: emailed,
        lang: lang,
        blog_locale: blog_locale,
        year: year
      ).ordered_by_published(sort)
    end

    def apply_filters(tag: nil, without_tag: nil, title: nil, emailed: nil, lang: nil, blog_locale: nil, year: nil)
      scope = all
      scope = scope.tagged_with_any(*Array(tag)) if tag
      scope = scope.tagged_without_any(*Array(without_tag)) if without_tag
      scope = scope.where.not(title: [ nil, "" ]) if title.to_s == "true"
      scope = scope.where(title: [ nil, "" ]) if title.to_s == "false"
      scope = scope.emailed if emailed.to_s == "true"
      scope = scope.not_emailed if emailed.to_s == "false"
      scope = scope.for_locale(lang, blog_locale) if lang
      scope = scope.for_year(year) if year.present?
      scope
    end

    def ordered_by_published(sort = nil)
      direction = sort.to_s == "asc" ? :asc : :desc
      order(published_at: direction, id: direction)
    end

    def for_locale(lang, blog_locale)
      locale = lang.to_s.downcase.split("-").first
      blog_locale == locale ? where(locale: [ locale, nil ]) : where(locale: locale)
    end

    def for_year(year)
      parsed_year = Integer(year, exception: false)
      return none unless parsed_year&.positive?

      start_date = Date.new(parsed_year, 1, 1)
      where(published_at: start_date..start_date.end_of_year.end_of_day)
    rescue Date::Error
      none
    end
  end
end
