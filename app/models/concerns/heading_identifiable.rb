module HeadingIdentifiable
  extend ActiveSupport::Concern

  included do
    before_save :add_heading_ids
  end

  private

    def add_heading_ids
      return unless content.body.present?

      original = content.body.to_html
      transformed = Html::HeadingIds.new.transform(original)
      self.content = transformed if transformed != original
    end
end
