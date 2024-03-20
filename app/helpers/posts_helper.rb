module PostsHelper
  include Pagy::Frontend

  def html_content?(string)
    /<[a-z][\s\S]*>/i.match?(string)
  end
end
