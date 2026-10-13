module App::SettingsHelper
  def date_format_options(blog)
    example = Date.new(Date.current.year, 3, 25)
    default = I18n.l(example, format: :post_date, locale: persisted_value(blog, :locale))

    [ [ "Language default (#{default})", "" ] ] +
      Blog::DATE_FORMATS.map { |value, format| [ example.strftime(format[:post_date]), value ] }
  end
end
