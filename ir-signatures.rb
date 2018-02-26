require 'net/http'
require 'net/https'
require 'json'
require 'cgi'
require 'erb'
require 'yaml'

$client = nil
$cookies = nil

def login(username, password)
  $client = Net::HTTP.new 'members.iracing.com', 80
  # $client.set_debug_output $stderr
  res = $client.post('/jforum/Login',
    "username=#{CGI::escape username}&password=#{CGI::escape password}")
  if res['Location'] and res['Location'] == 'http://members.iracing.com/jforum'
    $cookies = res.to_hash['set-cookie']&.collect{|ea| ea[/^.*?;/]}.join
  else
    $client = nil
  end
  $client != nil
end

# ugly hack, but better than the rest of the APIs
def get_member_brief_stats(custid)
  res = $client.get("/membersite/member/CareerStats.do?custid=#{custid}", {'Cookie' => $cookies})
  start = res.body.index('buf = \'{"memberSince"') + 7
  length = res.body.index("MemberProfile.driver = extractJSON") - 3 - start
  data = res.body[start, length]
  JSON.parse data
end

credentials = YAML.load IO.read 'credentials.yaml'
templates = YAML.load IO.read 'templates.yaml'
drivers = YAML.load IO.read 'drivers.yaml'

if not login(credentials[0][:username], credentials[0][:password])
  puts 'Login failed.'
  fail
end

drivers.each do |driver|
  sleep(5)
  stats = get_member_brief_stats(driver[:custId])
  if not stats
    puts "Cannot fetch stats for #{driver[:custId]}"
    return
  end
  template = (templates.select do |template| template[:name] == driver[:template] end).first
  driverData = {
    :name => driver[:displayName]
  }
  stats['licenses'].each do |lic|
    irating = lic['iRating']
    license = "#{CGI.parse('v=' + lic['licGroupDisplayName'])['v'][0].sub(/Class /, '')} #{lic['srPrime']}.#{lic['srSub']}"
    if lic['catId'] == 1
      driverData[:ovalIrating] = irating
      driverData[:ovalLicense] = license
    elsif lic['catId'] == 2
      driverData[:roadIrating] = irating
      driverData[:roadLicense] = license
    elsif lic['catId'] == 3
      driverData[:dirtovalIrating] = irating
      driverData[:dirtovalLicense] = license
    elsif lic['catId'] == 4
      driverData[:dirtroadIrating] = irating
      driverData[:dirtroadLicense] = license
    end
  end
  if template == nil
    puts "Template #{driver[:template]} not found for #{driver[:displayName]}"
  else
    text = "\"#{ERB.new(driver[:text]).result(OpenStruct.new(driverData).instance_eval { binding })}\""
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

