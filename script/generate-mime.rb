#!/usr/bin/env ruby

require "nokogiri"

class String
  alias inspect_old inspect

  def inspect
    x = b.inspect_old.gsub(/\\x([0-9a-f]{2})/i) do
      '\\%03o' % $1.to_i(16)
    end
    /[\\']/.match?(x) ? x : x.tr('"', "'")
  end
end

def str2int(s)
  return s.to_i(16) if s[0..1].downcase == "0x"
  return s.to_i(8) if s[0..0].downcase == "0"
  s.to_i(10)
end

def get_matches(parent)
  parent.elements.map { |match|
    if match["mask"]
      nil
    else
      type = match["type"]
      value = match["value"]
      offset = match["offset"].split(":").map { |x| x.to_i }
      offset = offset.size == 2 ? offset[0]..offset[1] : offset[0]
      case type
      when "string"
        value.gsub!(/\\(x[\dA-Fa-f]{1,2}|0\d{1,3}|\d{1,3}|.)/) { eval("\"\\#{$1}\"") }
      when "big16"
        value = str2int(value)
        value = ((value >> 8).chr + (value & 0xFF).chr)
      when "big32"
        value = str2int(value)
        value = (((value >> 24) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 8) & 0xFF).chr + (value & 0xFF).chr)
      when "little16"
        value = str2int(value)
        value = ((value & 0xFF).chr + (value >> 8).chr)
      when "little32"
        value = str2int(value)
        value = ((value & 0xFF).chr + ((value >> 8) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 24) & 0xFF).chr)
      when "host16" # use little endian
        value = str2int(value)
        value = ((value & 0xFF).chr + (value >> 8).chr)
      when "host32" # use little endian
        value = str2int(value)
        value = ((value & 0xFF).chr + ((value >> 8) & 0xFF).chr + ((value >> 16) & 0xFF).chr + ((value >> 24) & 0xFF).chr)
      when "byte"
        value = str2int(value)
        value = value.chr
      end
      children = get_matches(match)
      children.empty? ? [offset, value] : [offset, value, children]
    end
  }.compact
end

if ARGV.size != 1
  puts "Usage: #{$0} <freedesktop.org.xml>"
  exit 1
end

FILE = ARGV[0]
file = File.new(FILE)
doc = Nokogiri::XML(file)
extensions = {}
types = {}
magics = []
(doc / "mime-info/mime-type").each do |mime|
  comments = Hash[*(mime / "comment").map { |comment| [comment["xml:lang"], comment.inner_text] }.flatten]
  type = mime["type"]
  subclass = (mime / "sub-class-of").map { |x| x["type"] }
  exts = (mime / "glob").map { |x| x["pattern"] =~ /^\*\.([^\[\]]+)$/ ? $1.downcase : nil }.compact
  (mime / "magic").each do |magic|
    priority = magic["priority"].to_i
    matches = get_matches(magic)
    magics << [priority, type, matches]
  end
  unless exts.empty?
    exts.each { |x|
      extensions[x] = type unless extensions.include?(x)
    }
    types[type] = [exts, subclass, comments[nil]]
  end
end

magics = magics.sort { |a, b| [-a[0], a[1]] <=> [-b[0], b[1]] }

puts "# -*- coding: binary -*-"
puts "# Generated from #{FILE}"
puts "class MimeMagic"
puts "  # @private"
puts "  # :nodoc:"
puts "  EXTENSIONS = {"
extensions.keys.sort.each do |key|
  puts "    '#{key}' => '#{extensions[key]}',"
end
puts "  }"
puts "  # @private"
puts "  # :nodoc:"
puts "  TYPES = {"
types.keys.sort.each do |key|
  exts = types[key][0].sort.join(" ")
  parents = types[key][1].sort.join(" ")
  comment = types[key][2].inspect
  puts "    '#{key}' => [%w(#{exts}), %w(#{parents}), #{comment}],"
end
puts "  }"
puts "  # @private"
puts "  # :nodoc:"
puts "  MAGIC = ["
magics.each do |priority, type, matches|
  puts "    ['#{type}', #{matches.inspect}],"
end
puts "  ]"
puts "end"
