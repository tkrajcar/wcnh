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

  def self.wanted_list
    list = Wanted.desc(:amount)
    list = list.where(visible:true) unless R.orflags(R["enactor"],"Wr").to_bool
    return "> ".bold + "The wanted list is currently empty." unless list.count > 0
    ret = titlebar("Wanted List") + "\n"
    ret << "  #### #{'Name'.ljust(30)} Bounty Amount  Updated".cyan + "\n"
    list.each do |wanted|
      ret << "  "
      ret << wanted._id.rjust(4).bold.yellow
      ret << " "
      ret << wanted.name.bold.ljust(38)
      ret << wanted.amount.to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2').rjust(14).bold.cyan
      ret << wanted.updated_at.strftime("  %m/%d/%y")
      ret << " (INVISIBLE)".bold.red unless wanted.visible
      ret << "\n"
    end
    ret << "\n  Use #{'wanted <number>'.bold} to view more details of an entry.\n"
    ret << footerbar
  end

  def self.wanted_view(object)
    d = Wanted.where(_id: object)
    return "> ".bold + "That isn't a valid entry on the wanted list." if d.count == 0
    d = d.first
    return "> ".bold + "That isn't a valid entry on the wanted list." unless d.visible || R.orflags(R["enactor"],"Wr").to_bool
    ret = titlebar("Wanted List Entry #{object}") + "\n"
    ret << "Name:".ljust(30).cyan
    ret << d.name.bold
    ret << "\n"
    ret << "Bounty Amount:".ljust(30).cyan
    ret << d.amount.to_s.gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/,'\1,\2').bold.yellow
    ret << "\n"
    ret << "Contact:".ljust(30).cyan
    ret << d.contact
    ret << "\n"
    ret << "Info:".cyan
    ret << "\n"
    ret << d.info
    ret << "\n"
    ret << "                 THIS WANTED ENTRY IS NOT VISIBLE TO THE PUBLIC".bold.red + "\n" unless d.visible
    ret << footerbar
  end

  def self.wanted_set(object,field,value)
    d = Wanted.find_or_initialize_by(id: object)
    field.downcase!
    fields = %w(amount info name contact visible)
    return "> ".bold + "Invalid field. Valid fields are: #{fields.to_sentence}." unless fields.include?(field)
    if field == "visible"
      return "> ".bold + "Visible must be set to true or false." unless value == "true" || value == "false"
      value = value.to_bool
    end
    if field == "amount"
      return "> ".bold + "Amounts must be positive integers." unless value.to_i > 0
      value = value.to_i
    end

    d[field] = value
    d.save
    Logs::log_syslog("WANTED","#{R.penn_name(R["enactor"])} set #{field} on #{object} (#{d.name}) to #{value.to_s}.")
    "> ".bold + "Updated #{field.bold} to #{value.to_s} for wanted item #{object.bold} (#{d.name.bold})." 
  end

  def self.wanted_delete(object)
    d = Wanted.where(_id: object).first
    return "> ".bold + "That isn't a valid entry on the wanted list." if d.nil?
    d.delete
    Logs::log_syslog("WANTED","#{R.penn_name(R["enactor"])} deleted #{object} (#{d.name}).")
    return "> ".bold + "Deleted wanted entry #{object.bold}."
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

  class Wanted
    include Mongoid::Document
    include Mongoid::Timestamps

    identity :type => String # dbref
    field :name, :type => String # we store the name because a player might re-@name to avoid a bounty.
    field :amount, :type => Integer, :default => 0
    field :info, :type => String, :default => ""
    field :contact, :type => String, :default => ""
    field :visible, :type => Boolean, :default => false
  end
end
