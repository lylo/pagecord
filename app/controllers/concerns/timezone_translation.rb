module TimezoneTranslation
  extend ActiveSupport::Concern

  def active_support_time_zone_from_iana(iana_name)
    tzinfo = TZInfo::Timezone.get(iana_name)
    canonical = tzinfo.canonical_zone.name
    ActiveSupport::TimeZone::MAPPING.key(canonical) ||
      ActiveSupport::TimeZone[canonical]&.name
  rescue TZInfo::InvalidTimezoneIdentifier
    nil
  end
end
