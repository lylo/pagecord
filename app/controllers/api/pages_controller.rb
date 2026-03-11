class Api::PagesController < Api::BaseController
  include Pagy::Method

  before_action :set_page, only: %i[show update destroy]

  def index
    pages = Current.blog.pages.kept

    case params[:status]
    when "draft"
      pages = pages.draft
    when "published"
      pages = pages.published
    else
      pages = pages.published.released
    end

    pages = pages.where("published_at >= ?", Time.iso8601(params[:published_after])) if params[:published_after]
    pages = pages.where("published_at <= ?", Time.iso8601(params[:published_before])) if params[:published_before]

    @pagy, @pages = pagy(pages.order(published_at: :desc))
    set_pagination_headers(@pagy)

    render json: @pages.map { |page| page_json(page) }
  end

  def show
    render json: page_json(@page)
  end

  def create
    page = Current.blog.pages.build(page_params.merge(source: :api))

    if page.save
      render json: page_json(page), status: :created
    else
      render json: { errors: page.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @page.update(page_params)
      render json: page_json(@page)
    else
      render json: { errors: @page.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    Current.blog.update!(home_page_id: nil) if Current.blog.home_page_id == @page.id
    @page.discard!
    head :no_content
  end

  private

    def set_page
      @page = Current.blog.pages.kept.find_by!(token: params[:token])
    end

    def page_params
      permitted = params.except(:token).permit(:title, :content, :slug, :published_at, :canonical_url, :tags, :hidden, :locale, :status, :content_format, :show_in_navigation)
      permitted[:tags_string] = permitted.delete(:tags) if permitted.key?(:tags)

      if permitted.delete(:content_format) == "markdown" && permitted[:content].present?
        attributes, html = Post::Markdown.render(permitted[:content])
        attributes.each { |key, value| permitted[key] ||= value }
        permitted[:content] = html
      end

      permitted.merge(is_page: true)
    end

    def page_json(page)
      fields = %i[token title slug status published_at canonical_url tag_list hidden locale show_in_navigation created_at updated_at]
      page.as_json(only: fields).merge(
        content: page.content.to_s,
        is_page: true,
        is_home_page: Current.blog.home_page_id == page.id
      )
    end
end
