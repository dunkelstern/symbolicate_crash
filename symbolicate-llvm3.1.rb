#!/usr/bin/env ruby
require 'trollop'
require 'plist'

$llvm_nm='llvm-nm-3.1'
$llvm_dwarfdump='llvm-dwarfdump-3.1'

def symbolicate(line, base_address)
  if line.to_i > 0
    components = line.squeeze(" ").split(" ")
    # STACKFRAME, BINARY, ADDRESS, LOAD_ADDRESS, +, OFFSET

    address = components[2].hex
    load_address = components[3].hex
    address_offset = address - load_address + base_address
    address_hex = format("%#x", address_offset)

    symbol = `#{$llvm_dwarfdump} -address=#{address_hex} "#{$opts[:dsym]}"`
    newString = format("%-3d %-37s %#x %s", components[0].to_i, components[1], address, symbol)
    puts newString
  else
    puts line
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

if $opts[:archive]
  info     = Plist::parse_xml($opts[:archive] + '/Info.plist')
  appname  = info['ApplicationProperties']['ApplicationPath'].split('/')[1]
  basename = appname[0...-4]

  $opts[:dsym]       = File.join($opts[:archive], 'dSYMs', appname + '.dSYM', 'Contents', 'Resources', 'DWARF', basename)
  $opts[:executable] = File.join($opts[:archive], 'Products', 'Applications', appname, basename)
end

base_address = `#{$llvm_nm} "#{$opts[:executable]}" 2>/dev/null|grep __mh_execute_header`.hex

File.foreach($opts[:crash]) { |line|
  if line.include? basename
    line = symbolicate(line, base_address)
  else
    puts line
  end
}

