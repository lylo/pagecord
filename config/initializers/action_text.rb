# Add custom tags and attributes to ActionText's allowed list
# Prepend to sanitizer_allowed_tags to always include our custom tags
# regardless of when Lexxy sets allowed_tags
module ActionTextCustomTags
  CUSTOM_TAGS = %w[s u mark details summary aside].freeze
  CUSTOM_ATTRIBUTES = %w[data-lightbox-full-url data-highlight-language data-callout data-callout-title data-footnotes data-footnote-ref data-waveform data-duration playsinline id open].freeze

  def sanitizer_allowed_tags
    super + CUSTOM_TAGS
  end

  def sanitizer_allowed_attributes
    super + CUSTOM_ATTRIBUTES + %w[loading]
  end
end

# Lexxy stores an image's link as href on the attachment, next to caption
module ActionTextAttachmentHref
  def href
    node_attributes["href"].presence
  end
end

# Action Text finds each attachment's record by its sgid, one query apiece.
# While a body renders or lists its attachments, its records are loaded with
# one query per model and from_attachable_sgid answers from those.
module ActionTextBatchedAttachables
  LOADED = :action_text_loaded_attachables

  %i[ attachments attachables render_attachments to_rendered_html_with_layout ].each do |name|
    define_method(name) do |*args, **options, &block|
      with_attachables_loaded { super(*args, **options, &block) }
    end
  end

  private
    def with_attachables_loaded
      outer = ActiveSupport::IsolatedExecutionState[LOADED]
      ActiveSupport::IsolatedExecutionState[LOADED] = outer ? outer.merge(attachables_by_sgid) : attachables_by_sgid
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[LOADED] = outer
    end

    def attachables_by_sgid
      @attachables_by_sgid ||= begin
        gids = attachment_nodes.filter_map { |node| node["sgid"] }.uniq.index_with { |sgid|
          SignedGlobalID.parse(sgid, for: ActionText::Attachable::LOCATOR_NAME)
        }.compact
        records = GlobalID::Locator.locate_many(gids.values, ignore_missing: true).index_by { |record| [ record.class.name, record.id.to_s ] }

        gids.transform_values { |gid| records[[ gid.model_name, gid.model_id ]] }.compact
      end
    end
end

module ActionTextLoadedAttachableLookup
  def from_attachable_sgid(sgid, options = {})
    loaded = ActiveSupport::IsolatedExecutionState[ActionTextBatchedAttachables::LOADED] unless options[:only]
    loaded&.[](sgid) || super
  end
end

ActiveSupport.on_load(:action_text_content) do
  prepend ActionTextBatchedAttachables
  ActionText::Attachable.singleton_class.prepend(ActionTextLoadedAttachableLookup)
  ActionText::ContentHelper.prepend(ActionTextCustomTags)
  ActionText::Attachment.include(ActionTextAttachmentHref)
end
