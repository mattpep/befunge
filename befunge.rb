if ARGV.length != 1
  STDERR.puts "#{$0} [options] <befunge.b93>"
  exit 1
end

source_file = open(ARGV.shift)
source = source_file.read.split("\n").map(&:chars)

class BefungeError < StandardError; end

stack = Array.new

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
  STDERR.puts "Current location is #{x},#{y}"
  case source[y][x]
  when '<','v','>','^'
    direction = DIRECTIONS.invert[source[y][x]]
  when '?'
    STDERR.puts "  randdir"
    direction = DIRECTIONS.keys.sample
  when ' ',nil
    nil
  when '.'
    STDERR.puts "  printInt"
    i = stack.pop
    print i
  when '1'..'9'
    stack << source[y][x].to_i
  else
    STDERR.puts "row is #{source[y].join}"
    raise BefungeError.new "Unimplemented operator: #{source[y][x].inspect}"
  end

  STDERR.puts "    x:#{x}, y:#{y}: current character is #{source[y][x]} and direction is #{direction}, stack is #{stack} (string repr: #{stack.map{ |c| (0...256).include?(c) ? c.chr : 'X' }.join})"

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
