# Workaround for Lexxy 0.1.23.beta + Rails 8.2.0.alpha compatibility issue
# The prepended ActionTextTag module can't find the delegated dom_id method
# This adds the delegation directly to the module
#
# TODO: Remove when Lexxy fixes this upstream

Rails.application.config.to_prepare do
  Lexxy::ActionTextTag.module_eval do
    delegate :dom_id, to: ActionView::RecordIdentifier
  end
end
