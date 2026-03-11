class Api::HomePagesController < Api::BaseController
  before_action :set_home_page, only: %i[show update destroy]

  def show
    render json: page_json(@home_page)
  end

  def create
    page = Current.blog.pages.build(home_page_params.merge(source: :api))

    if page.save
      Current.blog.update!(home_page_id: page.id)
      render json: page_json(page), status: :created
    else
      render json: { errors: page.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @home_page.update(home_page_params)
      render json: page_json(@home_page)
    else
      render json: { errors: @home_page.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      @home_page.update!(title: "Home Page") if @home_page.title.blank?
      Current.blog.update!(home_page_id: nil)
    end

    head :no_content
  end

  private

    def set_home_page
      @home_page = Current.blog.home_page or raise ActiveRecord::RecordNotFound
    end

    def home_page_params
      permitted_content_params(
        :title, :content, :slug, :published_at, :canonical_url,
        :tags, :hidden, :locale, :status, :content_format,
        except_token: false
      ).merge(is_page: true, is_home_page: true)
    end

    def page_json(page)
      fields = %i[token title slug status published_at canonical_url tag_list hidden locale created_at updated_at]
      page.as_json(only: fields).merge(
        content: page.content.body.to_html,
        is_page: true,
        is_home_page: true
      )
    end
end
