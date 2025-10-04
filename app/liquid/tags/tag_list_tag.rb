module Tags
  class TagListTag < Liquid::Tag
    def render(context)
      blog = context.registers[:blog]
      view = context.registers[:view]

      # Get all unique tags from the blog's posts
      tags = blog.posts.visible.all_tags

      view.render(partial: "blogs/liquid/tag_list", locals: { tags: tags, blog: blog })
    end
  end
end
