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

@sites = Dir['../../*'].map {|path| Site.new path}

def recentFarmActivity
  threshold = Time.now.to_i - @days*24*60*60
  result = []
  @sites.each do |site|
    next unless (recent = site.recent) and recent.date > threshold
    next unless site.claimed? or site.pages.length > 1
    next if site.claim == 'http://WardCunningham.myopenid.com'
    title = recent.title || "Recent Changes"
    text = "In [http://#{site.name}#{@port||''} #{site.name}] with #{site.pages.length} pages."
    text += " [#{site.claim} claim]" if site.claimed?
    result << {:date => recent.date*1000, :site => "#{site.name}#{@port||''}", :slug => slug(title), :title => title, :text => text}
  end
  result.sort{|a,b|b[:date]<=>a[:date]}.each do |params|
    item :reference, params
  end
end

page 'Recent Farm Activity' do
  paragraph "Sites hosted by this farm with activity in the last #{@days} days."
  paragraph "See also [[About Activity Plugin]]."
  recentFarmActivity
end


