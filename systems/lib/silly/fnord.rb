module Silly
  class Fnord
    def self.true?(chance) (chance==0 or rand(chance)<1) end
    def self.build(string_array,chance=0) true?(chance) ? string_array[rand(string_array.length)] : "" end
    def self.in_place(chance=0) true?(chance) ? "in #{build(PLACES)}" : "" end
    def self.adjective(chance=0) build(ADJECTIVES, chance) end
    def self.name(chance=0) build(NAMES, chance) end
    def self.place(chance=0) build(PLACES, chance) end
    def self.preposition(chance=0) build(PREPOSITIONS, chance) end
    def self.action(chance=0) build(ACTIONS, chance) end
    def self.pronoun(chance=0) build(PRONOUNS, chance) end
    def self.intro(chance=0) build(INTROS, chance) end
    def self.noun(chance=0) build(NOUNS, chance) end
    def self.sentence(chance=0) normalize(eval('"'+build(SENTENCES,chance)+'"')) end
    def self.paragraph(chance=0)
      if true?(chance) then
        msg=""
        20.times { |i| msg+=true?(i) ? "#{sentence} " : "" }
        msg
      else
          ""
      end
    end
    def self.page(chance=0)
      if true?(chance) then
        msg=""
        20.times { |i| msg+=true?(i) ? "#{paragraph}\r\n" : "" }
        msg
      else
          ""
      end
    end
    def self.book
      msg=""
      18.times {|i| msg+=true?(i) ? "#{page}\r\n" : ""}
      msg
    end

    private
    def self.normalize(msg)
      while msg.include?("  ")
        msg.gsub!(/  /," ")
      end
      msg.gsub!(/^ /,"")
      msg.gsub!(/ \./,".")
      msg.gsub!(/[\s^]([aA])\s([aeiouhy])/,' \1n \2')
      msg[0]=msg[0,1].upcase
      while msg[/([^A-Z][\.\!\?\:])\s+([a-z])/]
        msg[/([^A-Z][\.\!\?\:])\s+([a-z])/]="#{$1} #{$2.upcase}"
      end
      msg
    end
  end
end
