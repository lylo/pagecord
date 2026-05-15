class DynamicVariable::PostListParams
  include DynamicVariable::Params

  def initialize(blog:, params_string: nil, params: nil)
    @blog = blog
    @params = params ? normalize_request_params(params) : parse_params(params_string)
  end

  def style
    @params[:style].to_s
  end

  def limit
    parsed_limit = Integer(@params[:limit], exception: false)
    parsed_limit if parsed_limit && parsed_limit >= 0
  end

  def filter_args(include_year: true)
    {}.tap do |args|
      args[:tag] = @params[:tag] if @params[:tag]
      args[:without_tag] = @params[:without_tag] if @params[:without_tag]
      args[:title] = @params[:title] if @params.key?(:title)
      args[:emailed] = @params[:emailed] if @params.key?(:emailed)
      args[:lang] = @params[:lang] if @params[:lang]
      args[:year] = @params[:year] if include_year && @params[:year]
      args[:sort] = @params[:sort] if @params[:sort]
      args[:blog_locale] = @blog.locale if @params[:lang]
    end
  end

  def query_params(include_year: true)
    {}.tap do |qp|
      qp[:tag] = Array(@params[:tag]).join(",") if @params[:tag]
      qp[:without_tag] = Array(@params[:without_tag]).join(",") if @params[:without_tag]
      qp[:title] = @params[:title].to_s if @params.key?(:title)
      qp[:emailed] = @params[:emailed].to_s if @params.key?(:emailed)
      qp[:lang] = @params[:lang] if @params[:lang]
      qp[:year] = @params[:year] if include_year && @params[:year]
      qp[:sort] = @params[:sort] if @params[:sort]
    end
  end

  private

    def normalize_request_params(params)
      {}.tap do |normalized|
        normalized[:style] = params[:style] if params[:style].present?
        normalized[:tag] = split_list_param(params[:tag]) if params[:tag].present?
        normalized[:without_tag] = split_list_param(params[:without_tag]) if params[:without_tag].present?
        normalized[:title] = params[:title] if params[:title].present?
        normalized[:emailed] = params[:emailed] if params[:emailed].present?
        normalized[:lang] = params[:lang] if params[:lang].present?
        normalized[:year] = params[:year] if params[:year].present?
        normalized[:sort] = params[:sort] if params[:sort].present?
      end
    end

    def split_list_param(value)
      value.to_s.split(",").map(&:strip).reject(&:blank?)
    end
end
