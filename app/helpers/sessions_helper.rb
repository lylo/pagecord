module SessionsHelper
  GREETINGS = [
      "Hi there",
      "Hello",
      "Hey Hey",
      "Now then",
      "Greetings",
      "Hiya",
      "Ahoy",
      "Yo yo",
      "Salut",
      "Ciao",
      "Hei",
      "Hola",
      "Howdy",
      "Hallo",
      "Aloha",
      "Namaste",
      "Hei"
    ].freeze

  def greeting
    GREETINGS.sample
  end
end
