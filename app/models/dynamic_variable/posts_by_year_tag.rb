class DynamicVariable::PostsByYearTag < DynamicVariable::PostsTag
  def initialize(blog:, view:, params_string:)
    super
    @style = "by_year"
  end
end
