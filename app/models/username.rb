class Username
  RESERVED = %w{ pricing about contact faq terms privacy careers blog
                 login signup feed rss pagecord }

  def self.reserved?(username)
    RESERVED.include?(username)
  end
end
