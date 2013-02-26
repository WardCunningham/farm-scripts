require 'rubygems'
require 'json'

# wiki utilities

def random
  (1..16).collect {(rand*16).floor.to_s(16)}.join ''
end

def slug title
  title.gsub(/\s/, '-').gsub(/[^A-Za-z0-9-]/, '').downcase()
end

def url text
  text.gsub(/(http:\/\/)?([a-zA-Z0-9._-]+?\.(net|com|org|edu)(\/[^ )]+)?)/,'[http:\/\/\2 \2]')
end

def domain text
  text.gsub(/((https?:\/\/)(www\.)?([a-zA-Z0-9._-]+?\.(net|com|org|edu|us|cn|dk|au))(\/[^ );]*)?)/,'[\1 \4]')
end

# journal actions

def create title
  @journal << {:type => :create, :id => random, :item => {:title => title}, :date => Time.now.to_i*1000}
end

def add item
  @story << item
  @journal << {:type => :add, :id => item[:id], :item => item, :date => Time.now.to_i*1000}
end

# story emiters

def item type, object={}
  object[:type] = type
  object[:id] = random()
  add object
end

def paragraph text
  item :paragraph, {:text => text}
end

def page title
  @story = []
  @journal = []
  create title
  yield
  page = {:title => title, :story => @story, :journal => @journal}
  File.open("../pages/#{slug(title)}", 'w') do |file|
    file.write JSON.pretty_generate(page)
  end
end

# generate pages

@days = 10
@port = ':1111' if `hostname` =~ /cg.local/

class Page
  def initialize path
    @path = path
  end
  def date
    @date ||= File.mtime(@path).to_i
  end
  def <=> page
    date <=> page.date
  end
  def object
    @object ||= JSON.parse(File.read(@path))
  end
  def slug
    File.basename @path
  end
  def title
    object['title'] || slug
  end
end

class Site
  def initialize path
    @path = path
  end
  def name
    File.basename @path
  end
  def pages
    return @pages unless @pages.nil?
    paths = Dir["#{@path}/pages/*"] || []
    @pages = paths.map{|path| Page.new path}
  end
  def recent
    pages.sort.last
  end
  def claim
    return @claim unless @claim.nil?
    identity = "#{@path}/status/open_id.identity"
    @claim = (File.exists? identity) ? `cat #{identity}` : ''
  end
  def claimed?
    ! claim.empty?
  end
end

def ago msec
  t = Time.now()
  secs = t.to_i - msec / 1000.0
  return "#{secs.floor} seconds ago" if (mins = secs/60) < 2
  return "#{mins.floor} minutes ago" if (hrs = mins/60) < 2
  return "#{hrs.floor} hours ago" if (days = hrs/24) < 2
  return "#{days.floor} days ago" if (weeks = days/7) < 2
  return "#{weeks.floor} weeks ago" if (months = days/31) < 2
  return "#{months.floor} months ago" if (years = days/365) < 2
  return "#{years.floor} years ago"
end

def diff plugin, slug
  pages = "../../../../client/plugins/#{plugin}/pages"
  local = JSON.parse(File.read "../pages/#{slug}")
  doc = JSON.parse(File.read "#{pages}/#{slug}")
  if (l = local['journal'].length) > (d = doc['journal'].length) then
    return "<br>[[#{local['title']}]] has #{l-d} new edits from #{ago local['journal'][d]['date']}."
  else
    return ''
  end
end

# Smallest-Federated-Wiki/data/farm/localhost/scripts

def forLocalAboutPages
  paragraph "<h3> Local About Pages"
  paragraph "We look for local about pages and check them against plugin pages, if any."
  Dir.glob '../pages/about-*-plugin' do |filename|
    local = JSON.parse(File.read filename)
    plugin =  $1 if filename.match /-(.*)-/
    pages = "../../../../client/plugins/#{plugin}/pages"
    info = ''
    if File.exists? pages
      info += " Has pages."
      if File.exists? "#{pages}/about-#{plugin}-plugin"
        info += " Has about."
        begin
          info += diff plugin, "about-#{plugin}-plugin"
        rescue
          info += " Can't diff [[#{"about-#{plugin}-plugin"}]]."
        end
      else
        info += " Needs about."
      end
    end
    paragraph "[[#{local['title']}]]. #{info}"
  end
end

def forPluginPages
  paragraph "<h3> Plugin Pages"
  paragraph "We check each plugin for expected pages and local copies of any extant page."
  plugins = "../../../../client/plugins"
  Dir.glob "#{plugins}/*" do |filename|
    next unless File.directory? filename
    plugin = $1 if filename.match /([^\/]+)$/
    info = ''
    if File.exists? "#{filename}/pages"
      if File.exists? "#{plugins}/#{plugin}/pages/about-#{plugin}-plugin"
      else
        info += " Needs about."
      end
      Dir.glob "#{filename}/pages/*" do |pagepath|
        slug = $1 if pagepath.match /([^\/]+)$/
        unless slug == "about-#{plugin}-plugin"
          if File.exists? "../pages/#{slug}"
            begin
              info += diff plugin, slug
            rescue
              info += " Can't diff [[#{slug}]]."
            end
          end
        end
      end
    else
      info += " Needs pages."
    end
    paragraph "[[About #{plugin.capitalize} Plugin]]. #{info}" unless info == ''
  end
end


def recentDocumentUpdates
  forLocalAboutPages
  forPluginPages
end

page 'Recent Document Updates' do
  paragraph "This is a mechanically generated list of plugin document updates produced by comparing <b>localhost/pages</b> to <b>clien/plugins/*/pages</b>."
  paragraph "Run from #{`pwd`}"
  recentDocumentUpdates
end


