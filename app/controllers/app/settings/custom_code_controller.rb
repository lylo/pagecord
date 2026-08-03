class App::Settings::CustomCodeController < AppController
  def show
  end

  def update
    if @blog.update(custom_code_params)
      log_custom_code_change
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to app_settings_custom_code_path, notice: "Custom code updated" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            error_stream("css-error", :custom_css),
            error_stream("footer-error", :custom_footer_html),
            error_stream("head-error", :custom_head_html),
            error_stream("body-error", :custom_body_html)
          ],
                 status: :unprocessable_entity
        end
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  private

    # turbo_stream.update renders a plain String as raw markup, and the custom
    # code errors quote the tags they object to.
    def error_stream(target, attribute)
      turbo_stream.update(target, ERB::Util.html_escape(@blog.errors[attribute].first.to_s))
    end

    def custom_code_params
      permitted_params = []
      permitted_params += [ :custom_css, :custom_footer_html ] if @blog.user.has_premium_access?
      permitted_params += [ :custom_head_html, :custom_body_html, :custom_code_enabled ] if custom_code_editable?

      params.require(:blog).permit(permitted_params)
    end

    def custom_code_editable?
      @blog.user.subscribed? && current_features.enabled?(:custom_code)
    end

    def log_custom_code_change
      changed = @blog.previous_changes.keys & %w[ custom_head_html custom_body_html custom_code_enabled ]
      return if changed.empty?

      Rails.logger.info "[CustomCode] blog=#{@blog.id} changed=#{changed.join(",")} head=#{@blog.custom_head_html.to_s.bytesize} body=#{@blog.custom_body_html.to_s.bytesize} enabled=#{@blog.custom_code_enabled}"
    end
end
