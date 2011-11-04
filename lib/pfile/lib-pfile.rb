require 'wcnh'

module PlayerFile
  R = PennJSON::Remote

#  def self.register_email(dbref, email)
#    p = Player.create(:email => email)
#
#    Player.all_of(:email => email).count.to_s
#  end

#  def self.find_email(email)
#    Player.all_of(:email => email).first.inspect

#  end

  # Add the <dbref> to the pfile for <email>. Returns _id of pfile.
  def self.register(email,dbref)
    return "#-1 INVALID DBREF" unless R.type(dbref) == "PLAYER"
    p = Pfile.find_or_create_by(:email => email)
    p.current_dbref = dbref
    p.save
    p.add_note("#{dbref} #{R.fullname(dbref)}",R["enactor"],"Char.new")
    R.attrib_set("#{dbref}/PFILE",p._id.to_s)
    #syslog("Pfile","Registered character #{dbref} #{R.fullname(dbref)} to #{p._id.to_s}.")
    return p._id.to_s
  end

  # Renders the pfile for <arg>. <arg> could be a name, dbref, or email.
  def self.view_file(arg)
    return ">".red + " No file found for '#{arg}'." unless p = Pfile.locate(arg)
    ret = titlebar("Playerfile for #{p.email} (#{p._id.to_s})") + "\n"
    p.notes.each do |note|
      ret << R.fullname(note.author).bold.cyan + "-".cyan + note.timestamp.strftime("%m/%d/%Y %H:%m").cyan + " (" + note.category.bold + "): ".cyan + note.text + "\n"
    end
    ret << footerbar
    return ret
  end

  # Return the 30 most recent connections for <arg>. <arg> as above.
  def self.ip(arg)

  end

  # Search pfile note text for the string.
  def self.search(term) # Search text
    return ">".red + " You must specify a search term." unless term.length > 0
    results = Pfile.where("notes.text" => /#{term}/i).all
    return ">".red + " No notes containing '#{term}'." unless results.size > 0
    ret = titlebar("Pfile notes containing '#{term}'") + "\n"
    # iterate over each Pfile that matched our query
    results.each do |p|
      # now search that Pfile's notes. (TODO: This seems terrible. :C)
      p.notes.where("text" => /#{term}/i).all.each do |n|
        ret << R.fullname(p.current_dbref).bold.yellow  + "-" + R.fullname(n.author).bold.cyan + "-".cyan + n.timestamp.strftime("%m/%d/%Y %H:%m").cyan + " (" + n.category.bold + "): ".cyan + n.text.gsub(/(#{term})/i,'\1'.bold.yellow.underline) + "\n"
      end
    end

    ret << footerbar
    return ret
  end

  # Add a new note to a pfile (search by arg)
  def self.add_note(arg,note,category)
    return ">".red + " No file found for '#{arg}'." unless p = Pfile.locate(arg)
    p.add_note(note,R["enactor"],category)
    return ">".red + " Added note to player file for " + R.fullname(p.current_dbref).bold + " (#{p.email}/#{p._id.to_s})."
  end

  # Log a connection to a pfile.
  def self.connect(pfile,ip,host,descriptor)

  end

  # Log a disconnection to a pfile.
  def self.disconnect(pfile,descriptor)

  end

  class Pfile
    include Mongoid::Document
    field :email, :type => String
    index :email, :unique => true
    field :current_dbref, :type => String

    embeds_many :notes, :class_name => "PlayerFile::Note"
    embeds_many :connections, :class_name => "PlayerFile::Connection"

    def add_note(note, author, category = "Misc")
      #p "Adding note #{note} by #{author} in #{category} to: #{self._id}"
      self.notes.create(:author => author, :text => note, :category => category)
    end

    # Given a dbref, player name/alias, or email, look for a pfile.
    def self.locate(term)
      db = R.pmatch(term)
      if(db =~ /^#\d/)
        # dbref match. Pull their pfile oid.
        begin
          Pfile.find(R.xget(db,"PFILE"))
        rescue Mongoid::Errors::DocumentNotFound, Mongoid::Errors::InvalidFind
          false
        end
      else
        # No dbref match. Try email.
        Pfile.first(:conditions => {:email => term})
      end
    end
  end

  class Note
    include Mongoid::Document
    embedded_in :pfiles, :class_name => "PlayerFile::Pfile"
    field :author, :type => String
    field :timestamp, :type => DateTime, :default => lambda { DateTime.now }
    field :text, :type => String
    field :category, :type => String, :default => "Misc"
  end

  class Connection
    include Mongoid::Document
    embedded_in :pfiles, :class_name => "PlayerFile::Pfile"
    field :connected, :type => DateTime, :default => lambda {DateTime.now}
    field :disconnected, :type => DateTime, :default => lambda {DateTime.now}
    field :ip, :type => String
    field :host, :type => String
    field :descriptor, :type => String
  end
end
