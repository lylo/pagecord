module DynamicVariable::Params
  private

    def parse_params(params_string)
      params = {}
      return params if params_string.blank?

      params_string.split("|").each do |param|
        param = param.strip
        next if param.blank?

        key, value = param.split(":", 2).map(&:strip)
        next if key.blank? || value.blank?

        value = value[1..-2] if value.start_with?('"', "'") && value.end_with?('"', "'")

        if key.in?(%w[tag without_tag]) && value.include?(",")
          value = value.split(",").map(&:strip)
        end

        params[key.to_sym] = if value.is_a?(Array)
          value
        elsif value =~ /^\d+$/
          value.to_i
        elsif value == "true"
          true
        elsif value == "false"
          false
        else
          value
        end
      end

      params
    end
end
