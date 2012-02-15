require 'wcnh'

module Dossier
  R = PennJSON::Remote

  # Add the <dbref> to the pfile for <email>. Returns _id of pfile.
  def self.view(object,page)
    dbref = R.locate(R["enactor"],object,"PTFailmny")
    return "> ".bold + "I can't find that object." if dbref == "#-1"
    return "> ".bold + "Multiple matches - be more specific or use the dbref." if dbref == "#-2"
    d = Dossier.find_or_create_by(id: dbref)

    ret = titlebar("Dossier for #{R.penn_name(dbref)}(#{dbref}), Page #{page}") + "\n"
    d.notes.desc("created_at").skip(20 * (page.to_i - 1)).limit(20).each do |note|
      ret << "#{R.penn_name(note.author).white.bold} at #{note.created_at.strftime("%m/%d/%y %H:%M").bold}: " .cyan
     ret << note.text << "\n"
    end
    ret << footerbar
    return ret
  end

  def self.add(object,content)
    dbref = R.locate(R["enactor"],object,"PTFailmny")
    return "> ".bold + "I can't find that object." if dbref == "#-1"
    return "> ".bold + "Multiple matches - be more specific or use the dbref." if dbref == "#-2"
    d = Dossier.find_or_create_by(id: dbref)
    R.u("#65/fn.new_dossier_note",dbref,R["enactor"],content)
    d.add_note(content,R["enactor"])
    "> ".bold + "You add a note to the dossier for #{R.penn_name(dbref).bold}."
  end

  class Dossier
    include Mongoid::Document
    include Mongoid::Timestamps
    identity :type => String # dbref

    embeds_many :notes, :class_name => "Dossier::Note"

    def add_note(note, author)
      self.notes.create(:author => author, :text => note)
    end
  end

  class Note
    include Mongoid::Document
    include Mongoid::Timestamps
    embedded_in :dossier, :class_name => "Dossier::Dossier"
    field :author, :type => String
    field :text, :type => String
  end
end
