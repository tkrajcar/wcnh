require 'wcnh'

module PlayerFile
  R = PennJSON::Remote

  # Add the <dbref> to the pfile for <email>. Returns _id of pfile.
  def self.register(email,dbref,primary = true)
    return "#-1 INVALID DBREF" unless R.type(dbref) == "PLAYER"

    p = Pfile.find_or_create_by(:email => email)
    # update their current_dbref in the pfile if this is a primary registration
    if primary
      p.current_dbref = dbref
      p.save
      lognote = "Primary registration: "
    else
      lognote = "Primary registration: "
    end
    lognote << "#{dbref}/#{R.fullname(dbref)}"
    p.add_note(lognote,R["enactor"],"Char.new")
    R.attrib_set("#{dbref}/PFILE",p._id.to_s)
    return p._id.to_s
  end

  # Renders the pfile for <arg>. <arg> could be a name, dbref, or email.
  def self.view_file(arg)
    return ">".red + " No file found for '#{arg}'." unless p = Pfile.locate(arg)
    ret = titlebar("Playerfile for #{p.email} (#{p._id.to_s})") + "\n"
    p.notes.desc("timestamp").each do |note|
      ret << R.penn_name(note.author).bold.cyan + "-".cyan + note.timestamp.strftime("%m/%d/%Y %H:%M").cyan + " (" + note.category.bold + "): ".cyan + note.text + "\n"
    end
    ret << footerbar
    return ret
  end

  # Return the 30 most recent connections for <arg>. <arg> as above.
  def self.view_connections(arg)
    return ">".red + " No file found for '#{arg}'." unless p = Pfile.locate(arg)
    ret = titlebar("Connections for #{p.email} (#{p._id.to_s})") + "\n"
    p.connections.desc(:disconnected).limit(20).each do |conn|
      ret << conn.connected.strftime("%m/%d/%Y %H:%M").cyan + "-"
      if conn.disconnected.to_s == ""
        ret << "Connected  ".bold
      else
        ret << conn.disconnected.strftime("%m/%d %H:%M")
      end
      if conn.dbref
        ret << "#{conn.dbref} #{R.penn_name(conn.dbref)}"[0..15].ljust(15).yellow
      else
        ret << "".ljust(15)
      end
      ret << conn.host[0...35] + "\n"
    end
    ret << footerbar
    return ret
  end

  def self.search_connections(term)
    return ">".red + " You must specify a search term." unless term.length > 0
    results = Pfile.any_of({"connections.host" => /#{term}/i}, {"connections.ip" => /#{term}/i}).all
    return ">".red + " No connections matching '#{term}'." unless results.size > 0
    ret = titlebar("Pfiles with connections matching #{term}") + "\n"
    results.each do |p|
      ret << "#{R.penn_name(p.current_dbref).bold.cyan} (#{p.email.bold}/#{p._id.to_s}):\n"
      p.connections.any_of({:host => /#{term}/i}, {:ip => /#{term}/i}).desc(:disconnected).each do |conn|
        ret << conn.connected.strftime("%m/%d/%Y %H:%M").cyan + " "
        if conn.disconnected.to_s == ""
          ret << "Connected  ".bold
        else
          ret << conn.disconnected.strftime("%m/%d %H:%M")
        end

        if conn.dbref
           ret << "#{conn.dbref} #{R.penn_name(conn.dbref)}"[0..15].ljust(15).yellow
         else
           ret << "".ljust(15)
         end
        ret << conn.host[0...35].gsub(/(#{term})/i,'\1'.bold.yellow.underline) + "\n"
      end
    end
    ret << footerbar
    return ret
  end

  # Search pfile note text for the string.
  def self.search(term) # Search text
    return ">".red + " You must specify a search term." unless term.length > 0
    results = Pfile.where("notes.text" => /#{term}/i).all
    return ">".red + " No notes containing '#{term}'." unless results.size > 0
    ret = titlebar("Pfile notes containing '#{term}'") + "\n"
    # iterate over each Pfile that matched our query
    results.each do |p|
      p.notes.where("text" => /#{term}/i).desc("timestamp").each do |n|
        ret << R.penn_name(p.current_dbref).bold.yellow  + "-" + R.penn_name(n.author).bold.cyan + "-".cyan + n.timestamp.strftime("%m/%d/%Y %H:%M").cyan + " (" + n.category.bold + "): ".cyan + n.text.gsub(/(#{term})/i,'\1'.bold.yellow.underline) + "\n"
      end
    end

    ret << footerbar
    return ret
  end

  # Add a new note to a pfile (search by arg)
  def self.add_note(arg,note,category)
    return ">".red + " No file found for '#{arg}'." unless p = Pfile.locate(arg)
    p.add_note(note,R["enactor"],category)
    return ">".red + " Added note to player file for " + R.penn_name(p.current_dbref).bold + " (#{p.email}/#{p._id.to_s})."
  end

  # Log a connection to a pfile.
  def self.connect(pfile,ip,host,descriptor,dbref)
    p = Pfile.find(pfile)
    p.connections.create(:ip => ip, :host => host, :descriptor => descriptor, :connected => DateTime.now, :dbref => dbref, :name => R.penn_name(dbref))
  end

  # Log a disconnection to a pfile.
  def self.disconnect(pfile,descriptor)
    p = Pfile.find(pfile)
    conn = p.connections.where(:descriptor => descriptor).first
    conn.disconnected = DateTime.now
    conn.save
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
      if(db != "#-1" && db =~ /^#\d/)
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
    field :disconnected, :type => DateTime
    field :ip, :type => String
    field :host, :type => String
    field :descriptor, :type => String
    field :dbref, :type => String
    field :name, :type => String
  end
end
