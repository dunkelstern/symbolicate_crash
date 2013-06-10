#!/usr/bin/env ruby
require 'trollop'
require 'plist'

$atos='atos'

def symbolicate(line, basename)
  if ( line =~ /^[0-9](.*)/ )
    components = line.squeeze(" ").split(" ")
    # STACKFRAME, BINARY, ADDRESS, LOAD_ADDRESS, +, OFFSET

    address = components[2].hex
    load_address = components[3].hex
    
    newString = ''
    if line.include? basename
      symbol = `#{$atos} -arch #{$opts[:arch]} -o "#{$opts[:executable]}" -l #{format("%#x", load_address)} #{format("%#x", address)} 2>/dev/null`
      symbol.gsub!(/ \(in #{basename}\) /, ' ')
      symbol.gsub!(/^__[0-9]*/, '')
      newString = format("%-4d %-37s %#010x %s", components[0].to_i, components[1], address, symbol)
    else
      newString = format("%-4d %-37s %#010x %#010x + %d", components[0].to_i, components[1], address, load_address, components[5].to_i)
    end
  else
    line
  end
end

$opts = Trollop::options do
  opt :executable, "Specify executable directly, heuristics employed if app-bundle given", :type => :string
  opt :archive, "Specify path to *.xcarchive bundle", :type => :string
  opt :crash, "Specify crash file to symbolicate", :type => :string
  opt :arch, "Specify architecture to use", :type => :string, :default => "armv7"
end

exit 1 unless $opts[:archive] || $opts[:executable]
exit 2 unless $opts[:crash]

appname = ''
basename = ''
if $opts[:archive]
  info     = Plist::parse_xml($opts[:archive] + '/Info.plist')
  appname  = info['ApplicationProperties']['ApplicationPath'].split('/')[1]
  basename = appname[0...-4]

  $opts[:executable] = File.join($opts[:archive], 'Products', 'Applications', appname, basename)
else
  basename = File.basename($opts[:executable])
  if basename.include? ".app"
    Dir.foreach($opts[:executable]) do |item|
      next if item.start_with? '_' or item.start_with? '.' or not File.executable? item
      $opts[:executable] = $opts[:executable] + "/" + item
      basename = item
      break
    end
  end
end

translate_symbols = true
File.foreach($opts[:crash]) { |line|
  if line.include? 'Binary Images'
    translate_symbols = false
  end
  if translate_symbols
    line = symbolicate(line, basename)
  end
  puts line
}

