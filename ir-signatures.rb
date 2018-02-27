require 'net/http'
require 'net/https'
require 'json'
require 'cgi'
require 'erb'
require 'yaml'

require './ruby-ir-httpdata/ir-httpdata'

credentials = YAML.load IO.read 'credentials.yaml'
templates = YAML.load IO.read 'templates.yaml'
drivers = YAML.load IO.read 'drivers.yaml'

if not login(credentials[0][:username], credentials[0][:password])
  puts 'Login failed.'
  fail
end

class DataProxy
  @custId
  @name
  @stats
  def initialize(custId, name)
    @custId = custId
    @name = name
  end

  def name
    @name
  end

  #category: Oval, Road, Dirt+Oval, Dirt+Road
  #catId: 1,2,3,4

  def wins(category)
    if not @stats
      @stats = get_career_stats(@custId)
    end
    (@stats.select do |s| s['category'] == category end).first['wins']
  end

  def starts(category)
    if not @stats
      @stats = get_career_stats(@custId)
    end
    (@stats.select do |s| s['category'] == category end).first['starts']
  end

  def irating(catId)
    get_irating(@custId, catId)
  end

  def license_class(catId)
    get_license_class(@custId, catId)
  end
end

drivers.each do |driver|
  sleep(5)
  proxy = DataProxy.new(driver[:custId], driver[:displayName])
  template = (templates.select do |template| template[:name] == driver[:template] end).first
  if template == nil
    puts "Template #{driver[:template]} not found for #{driver[:displayName]}"
  else
    namespace = OpenStruct.new({:proxy => proxy})
    text = "\"#{ERB.new(driver[:text]).result(namespace.instance_eval { binding })}\""
    command =  "convert templates/#{template[:name]}.png "
    command << "-font '#{template[:fontFamily]}' -pointsize #{template[:fontSize]} "
    if template[:outline]
      command << "-fill '#{template[:outlineColor]}' -annotate +#{template[:textPositionX]-1}+#{template[:textPositionY]} #{text} "
      command << "-fill '#{template[:outlineColor]}' -annotate +#{template[:textPositionX]+1}+#{template[:textPositionY]} #{text} "
      command << "-fill '#{template[:outlineColor]}' -annotate +#{template[:textPositionX]}+#{template[:textPositionY]-1} #{text} "
      command << "-fill '#{template[:outlineColor]}' -annotate +#{template[:textPositionX]}+#{template[:textPositionY]+1} #{text} "
    end
    command << "-fill '#{template[:fontColor]}' -annotate +#{template[:textPositionX]}+#{template[:textPositionY]} #{text} "
    command << "signatures/#{driver[:custId]}.png"
    puts command
    `#{command}`
  end
end

