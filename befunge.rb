require 'getoptlong'
$debug = false
opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--debug', '-d', GetoptLong::NO_ARGUMENT ]
)

USAGE = <<-EOT
Usage:
  #{$0} [options] <befunge.b93>

-h, --help
    show help

-d, --debug
    show debug output on stderr during exection
EOT

opts.each do |opt,arg|
  case opt
  when '--help'
    STDERR.puts USAGE
    exit 1
  when '--debug'
    $debug = true
  end
end

def debug(s)
  puts s if $debug
end


if ARGV.length != 1
  STDERR.puts "#{$0} [options] <befunge.b93>"
  exit 1
end

source_file = open(ARGV.shift)
source = source_file.read.split("\n").map(&:chars)

class BefungeError < StandardError; end

stack = Array.new
string_mode = false

DIRECTIONS = {
  left: '<',
  right: '>',
  up: '^',
  down: 'v'
}

x = 0
y = 0
direction = :right


while true
  if string_mode
    if source[y][x] == '"'
      string_mode = false
    else
      stack << source[y][x].ord
      debug "Added character. Stack is now #{stack}"
    end
  else
    debug "Current location is #{x},#{y}"
    case source[y][x]
    when '"'
      string_mode = true
    when '<','v','>','^'
      direction = DIRECTIONS.invert[source[y][x]]
    when ':'
      debug "  dup"
      top = stack.pop.to_i
      2.times { stack << top }
    when '|'
      debug "  vIF"
      top = stack.pop
      if top.nil? || top.zero?
        direction = :down
      else
        direction = :up
      end
    when '?'
      debug "  randdir"
      direction = DIRECTIONS.keys.sample
    when '_'
      debug "  hIF"
      top = stack.pop
      if top.nil? || top.zero?
        direction = :right
      else
        direction = :left
      end
    when ' ',nil
      nil
    when '.'
      debug "  printInt"
      i = stack.pop
      print i
    when '$'
      debug "  discard"
      stack.pop
    when '+','-','*','/','%'
      op = source[y][x]
      debug "  op: #{op}"
      debug "    stack is #{stack} (will take two values)"
      a = stack.pop
      b = stack.pop
      debug "    got these two values: a:#{a}, b:#{b}"
      stack << b.send(op.to_sym, a)
    when '\\'
      debug "  switch"
      a = stack.pop
      b = stack.pop
      stack << a
      stack << b
    when '@'
      debug "  EXIT"
      exit
    when '&'
      stack << gets.to_i
      debug "  getInt"
      debug "    got result #{stack.last}"
    when ','
      debug "  printChar"
      print stack.pop.chr
    when '0'..'9'
      stack << source[y][x].to_i
    else
      debug "row is #{source[y].join}"
      raise BefungeError.new "Unimplemented operator: #{source[y][x].inspect}"
    end
  end

  debug "    x:#{x}, y:#{y}: current character is #{source[y][x]} and direction is #{direction}, stack is #{stack} (string repr: #{stack.map{ |c| (0...256).include?(c) ? c.chr : 'X' }.join})"

  # move
  case direction
  when :left
    x -= 1
    x = source.first.size - 1 if x < 0
  when :right
    x += 1
    x = 0 if x >= source.first.size
  when :up
    y -= 1
    y = source.size - 1 if y < 0
  when :down
    y += 1
    y = 0 if y > source.size
  else
    raise BefungeError.new "confused about direction"
  end
end
