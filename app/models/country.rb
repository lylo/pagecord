class Country
  # ISO 3166-1 alpha-2 codes with names and flag emojis
  COUNTRIES = {
    "US" => { name: "United States", flag: "\u{1F1FA}\u{1F1F8}" },
    "GB" => { name: "United Kingdom", flag: "\u{1F1EC}\u{1F1E7}" },
    "DE" => { name: "Germany", flag: "\u{1F1E9}\u{1F1EA}" },
    "FR" => { name: "France", flag: "\u{1F1EB}\u{1F1F7}" },
    "CA" => { name: "Canada", flag: "\u{1F1E8}\u{1F1E6}" },
    "AU" => { name: "Australia", flag: "\u{1F1E6}\u{1F1FA}" },
    "JP" => { name: "Japan", flag: "\u{1F1EF}\u{1F1F5}" },
    "IN" => { name: "India", flag: "\u{1F1EE}\u{1F1F3}" },
    "BR" => { name: "Brazil", flag: "\u{1F1E7}\u{1F1F7}" },
    "NL" => { name: "Netherlands", flag: "\u{1F1F3}\u{1F1F1}" },
    "ES" => { name: "Spain", flag: "\u{1F1EA}\u{1F1F8}" },
    "IT" => { name: "Italy", flag: "\u{1F1EE}\u{1F1F9}" },
    "SE" => { name: "Sweden", flag: "\u{1F1F8}\u{1F1EA}" },
    "CH" => { name: "Switzerland", flag: "\u{1F1E8}\u{1F1ED}" },
    "PL" => { name: "Poland", flag: "\u{1F1F5}\u{1F1F1}" },
    "BE" => { name: "Belgium", flag: "\u{1F1E7}\u{1F1EA}" },
    "AT" => { name: "Austria", flag: "\u{1F1E6}\u{1F1F9}" },
    "DK" => { name: "Denmark", flag: "\u{1F1E9}\u{1F1F0}" },
    "NO" => { name: "Norway", flag: "\u{1F1F3}\u{1F1F4}" },
    "FI" => { name: "Finland", flag: "\u{1F1EB}\u{1F1EE}" },
    "PT" => { name: "Portugal", flag: "\u{1F1F5}\u{1F1F9}" },
    "IE" => { name: "Ireland", flag: "\u{1F1EE}\u{1F1EA}" },
    "NZ" => { name: "New Zealand", flag: "\u{1F1F3}\u{1F1FF}" },
    "SG" => { name: "Singapore", flag: "\u{1F1F8}\u{1F1EC}" },
    "HK" => { name: "Hong Kong", flag: "\u{1F1ED}\u{1F1F0}" },
    "KR" => { name: "South Korea", flag: "\u{1F1F0}\u{1F1F7}" },
    "TW" => { name: "Taiwan", flag: "\u{1F1F9}\u{1F1FC}" },
    "CN" => { name: "China", flag: "\u{1F1E8}\u{1F1F3}" },
    "MX" => { name: "Mexico", flag: "\u{1F1F2}\u{1F1FD}" },
    "AR" => { name: "Argentina", flag: "\u{1F1E6}\u{1F1F7}" },
    "CL" => { name: "Chile", flag: "\u{1F1E8}\u{1F1F1}" },
    "CO" => { name: "Colombia", flag: "\u{1F1E8}\u{1F1F4}" },
    "ZA" => { name: "South Africa", flag: "\u{1F1FF}\u{1F1E6}" },
    "RU" => { name: "Russia", flag: "\u{1F1F7}\u{1F1FA}" },
    "UA" => { name: "Ukraine", flag: "\u{1F1FA}\u{1F1E6}" },
    "CZ" => { name: "Czech Republic", flag: "\u{1F1E8}\u{1F1FF}" },
    "RO" => { name: "Romania", flag: "\u{1F1F7}\u{1F1F4}" },
    "HU" => { name: "Hungary", flag: "\u{1F1ED}\u{1F1FA}" },
    "GR" => { name: "Greece", flag: "\u{1F1EC}\u{1F1F7}" },
    "TR" => { name: "Turkey", flag: "\u{1F1F9}\u{1F1F7}" },
    "IL" => { name: "Israel", flag: "\u{1F1EE}\u{1F1F1}" },
    "AE" => { name: "United Arab Emirates", flag: "\u{1F1E6}\u{1F1EA}" },
    "SA" => { name: "Saudi Arabia", flag: "\u{1F1F8}\u{1F1E6}" },
    "EG" => { name: "Egypt", flag: "\u{1F1EA}\u{1F1EC}" },
    "ID" => { name: "Indonesia", flag: "\u{1F1EE}\u{1F1E9}" },
    "MY" => { name: "Malaysia", flag: "\u{1F1F2}\u{1F1FE}" },
    "TH" => { name: "Thailand", flag: "\u{1F1F9}\u{1F1ED}" },
    "VN" => { name: "Vietnam", flag: "\u{1F1FB}\u{1F1F3}" },
    "PH" => { name: "Philippines", flag: "\u{1F1F5}\u{1F1ED}" },
    "PK" => { name: "Pakistan", flag: "\u{1F1F5}\u{1F1F0}" },
    "BD" => { name: "Bangladesh", flag: "\u{1F1E7}\u{1F1E9}" },
    "NG" => { name: "Nigeria", flag: "\u{1F1F3}\u{1F1EC}" },
    "KE" => { name: "Kenya", flag: "\u{1F1F0}\u{1F1EA}" },
    "LU" => { name: "Luxembourg", flag: "\u{1F1F1}\u{1F1FA}" },
    "SK" => { name: "Slovakia", flag: "\u{1F1F8}\u{1F1F0}" },
    "HR" => { name: "Croatia", flag: "\u{1F1ED}\u{1F1F7}" },
    "SI" => { name: "Slovenia", flag: "\u{1F1F8}\u{1F1EE}" },
    "BG" => { name: "Bulgaria", flag: "\u{1F1E7}\u{1F1EC}" },
    "RS" => { name: "Serbia", flag: "\u{1F1F7}\u{1F1F8}" },
    "LT" => { name: "Lithuania", flag: "\u{1F1F1}\u{1F1F9}" },
    "LV" => { name: "Latvia", flag: "\u{1F1F1}\u{1F1FB}" },
    "EE" => { name: "Estonia", flag: "\u{1F1EA}\u{1F1EA}" },
    "IS" => { name: "Iceland", flag: "\u{1F1EE}\u{1F1F8}" },
    "MT" => { name: "Malta", flag: "\u{1F1F2}\u{1F1F9}" },
    "CY" => { name: "Cyprus", flag: "\u{1F1E8}\u{1F1FE}" }
  }.freeze

  attr_reader :code

  def initialize(code)
    @code = code&.upcase
  end

  def name
    return "Unknown" if unknown?

    data = COUNTRIES[code]
    data ? data[:name] : code
  end

  def flag
    return "\u{1F30D}" if unknown? # Globe emoji for unknown

    data = COUNTRIES[code]
    data ? data[:flag] : country_code_to_flag(code)
  end

  def unknown?
    code.blank? || code == "XX" || code == "T1" # XX = unknown, T1 = Tor
  end

  private

    # Convert ISO country code to flag emoji (works for any valid 2-letter code)
    def country_code_to_flag(code)
      return "\u{1F30D}" if code.nil? || code.length != 2

      code.upcase.chars.map { |c| (c.ord - "A".ord + 0x1F1E6).chr("UTF-8") }.join
    end
end
