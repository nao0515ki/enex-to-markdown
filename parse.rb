require 'nokogiri'
require 'shellwords'
require 'pry'

def titles(file = './notes.enex')
  parsed = Nokogiri::XML File.read file
  parsed.xpath('//title').map(&:content).map(&:shellescape)
end

def content(note_title)
  command = "/usr/local/bin/geeknote show '#{note_title}'"
  IO.popen(command, err: [:child, :out]) do |io|
    yield io
  end
end

def ignore_lines
  ["/usr/local/lib/python2.7/dist-packages/beautifulsoup4-4.4.0-py2.7.egg/bs4/__init__.py:166: UserWarning: No parser was explicitly specified, so I'm using the best available HTML parser for this system (\"lxml\"). This usually isn't a problem, but if you run this code on another system, or in a different virtual environment, it may use a different parser and behave differently.\n", "\n", "To get rid of this warning, change this:\n", "\n", " BeautifulSoup([your markup])\n", "\n", "to this:\n", "\n", " BeautifulSoup([your markup], \"lxml\")\n"]
end

def output_note(note_title)
  return unless note_exists?(note_title)
  filename = "./notes/#{note_title.gsub '/', '_'}.txt"
  puts "Outputting '#{note_title}'"
  content(note_title) do |io|
    File.open(filename, 'w') do |file|
      lines = (io.readlines - ignore_lines).join ''
      file.write lines
    end
  end
end

def note_exists?(note_title)
  command = "/usr/local/bin/geeknote find --search '#{note_title}'"
  found = true
  IO.popen(command, err: [:child, :out]) do |io|
    out = io.readlines.join ''
    found = out.match(/Notes have not been found/).nil?
  end
  found
end

def delete(note_title)
  return unless note_exists?(note_title)
  puts "Deleting '#{note_title}'"
  command = "/usr/local/bin/geeknote remove --note \"#{note_title}\""
  IO.popen(command, 'r+', err: [:child, :out]) do |io|
    io.puts 'Yes'
    puts io.readlines
  end
  puts "Finished deleting #{note_title}"
end

def run
  puts "There are #{titles.count} notes to migrate."
  output_note titles.first
  delete titles.first
  # titles.each do |title|
  #   output_note title
  #   delete title
  # end
  puts 'All done migrating notes.'
end

run if __FILE__ == $PROGRAM_NAME
