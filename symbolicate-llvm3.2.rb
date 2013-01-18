#!/usr/bin/env ruby
require 'trollop'
require 'plist'

$llvm_nm='llvm-nm-3.2'
$llvm_dwarfdump='llvm-dwarfdump-3.2'

def symbolicate(line, base_address, basename)
  if ( line =~ /^[0-9](.*)/ )
    components = line.squeeze(" ").split(" ")
    # STACKFRAME, BINARY, ADDRESS, LOAD_ADDRESS, +, OFFSET

    address = components[2].hex
    load_address = components[3].hex
    address_offset = address - load_address + base_address
    address_hex = format("%#x", address_offset)

    newString = ''
    if line.include? basename
      symbols = `#{$llvm_dwarfdump} --functions --address=#{address_hex} "#{$opts[:dsym]}"`
      parts = symbols.split(/\n/).map { |s| s.gsub(/\n/, '') }
      newString = format("%-4d %-37s %#010x %s (%s)", components[0].to_i, components[1], address, parts[0], File.basename(parts[1]))
    else
      newString = format("%-4d %-37s %#010x %#010x + %d", components[0].to_i, components[1], address, load_address, components[5].to_i)
    end
  else
    line
  end
end

$opts = Trollop::options do
  opt :dsym, "Specify DSYM filename directly", :type => :string
  opt :executable, "Specify executable directly", :type => :string
  opt :archive, "Specify path to *.xcarchive bundle", :type => :string
  opt :crash, "Specify crash file to symbolicate", :type => :string
end

exit 1 unless $opts[:archive] || ($opts[:dsym] && $opts[:executable])
exit 2 unless $opts[:crash]

appname = ''
basename = ''
if $opts[:archive]
  info     = Plist::parse_xml($opts[:archive] + '/Info.plist')
  appname  = info['ApplicationProperties']['ApplicationPath'].split('/')[1]
  basename = appname[0...-4]

  $opts[:dsym]       = File.join($opts[:archive], 'dSYMs', appname + '.dSYM', 'Contents', 'Resources', 'DWARF', basename)
  $opts[:executable] = File.join($opts[:archive], 'Products', 'Applications', appname, basename)
else
  appname = $opts[:executable] + '.app'
  basename = appname[0...-4]
end

base_address = `#{$llvm_nm} "#{$opts[:executable]}" 2>/dev/null|grep __mh_execute_header`.hex

translate_symbols = true
File.foreach($opts[:crash]) { |line|
  if line.include? 'Binary Images'
    translate_symbols = false
  end
  if translate_symbols
    line = symbolicate(line, base_address, basename)
  end
  puts line
}

