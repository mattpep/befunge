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

class Array
  def expand(width=80, height=25)
    entries.map {|row| row + [' '] * (width - row.size) } + Array.new(height-entries.count) { [' '] * width }
  end
  def normalize(fill_char=' ')
    max_row_size = entries.map(&:size).max
    entries.map do |row|
      deficit = max_row_size - row.size
      row + [fill_char] * deficit
    end
  end
  def normalize!(fill_char=' ')
    replace normalize(fill_char)
  end
  def expand!(width=80, height=25)
    replace expand(width, height)
  end
end

source_file = open(ARGV.shift)
source = source_file.read.split("\n").map(&:chars)

class BefungeError < StandardError; end

stack = Array.new
string_mode = false
bridge = false
source.normalize!
source.expand!

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
  elsif bridge
    debug "Current location is #{x},#{y}"
    debug "Skipping operation: #{source[y][x]}"
    bridge = false
  else
    debug "Current location is #{x},#{y}"
    case source[y][x]
    when '#'
      debug "  bridge"
      bridge = true
    when 'p'
      debug "  put"
      get_y = stack.pop
      get_x = stack.pop
      val = stack.pop
      debug "    x is #{get_x}"
      debug "    y is #{get_y}"
      debug "    val is #{val}"
      source[get_y][get_x] = val.chr
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
    when 'g'
      debug "  get"
      get_y = stack.pop
      get_x = stack.pop
      debug "    x is #{get_y}"
      debug "    y is #{get_x}"
      debug "    source row is #{source[get_y].join}"
      debug "    char is #{source[get_y][get_x]}"
      stack << source[get_y][get_x].ord
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
    when '!'
      debug "  NOT"
      val = stack.pop
      stack << (val.zero? ? 1 : 0)
    when '`'
      debug "  gt"
      debug "    stack is #{stack} (will take two values)"
      a = stack.pop
      b = stack.pop
      debug "    got these two values: a:#{a}, b:#{b}"
      stack << (b > a ? 1 : 0)
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
