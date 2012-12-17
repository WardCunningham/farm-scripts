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

def activeSites
  threshold = Time.now.to_i - @days*24*60*60
  result = []
  Dir['../../*'].each do |path|
    pages = Dir["#{path}/pages/*"]
    dates = pages.map{|pagePath| File.mtime(pagePath).to_i}
    date = dates.sort.first
    next unless date and  date > threshold
    site = File.basename path
    title = "Recent Changes"
    text = "#{site} has #{pages.length} pages"
    claim = "#{path}/status/open_id.identity"
    text += " [#{`cat #{claim}`} claim]" if File.exists? claim
    result << {:date => date*1000, :site => "#{site}#{@port||''}", :slug => slug(title), :title => title, :text => text}
  end
  result
end

page 'Recent Farm Activity' do
  paragraph "Sites hosted by this farm with activity in the last #{@days} days."
  paragraph "See also [[About Activity Plugin]]."
  activeSites.sort{|a,b|b[:date]<=>a[:date]}.each do |params|
    item :reference, params
  end
end


