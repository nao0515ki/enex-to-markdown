require 'nokogiri'
require 'reverse_markdown'
require 'date'
require 'pry'

def first(note)
  value = Nokogiri::XML(
                note.children.search('content').first
               ).xpath('//div')
  return if value.empty?
  ReverseMarkdown.convert(value.last.to_html)
end

def content(note)
  return first(note) unless first(note).nil?
  content = Nokogiri::XML noten
    .children
    .search('content')
    .first
    .search('en-note').first.children.to_html

  ReverseMarkdown.convert content
end

def source(note)
  source = note.search('note-attributes').first.search('source-url')
  return source.first.content unless source.empty?
end

def parts(note)
  [
    note.children.search('title').first.content,
    content(note),
    note.children.search('tag').map(&:content),
    DateTime.parse(note.children.search('created').first.content),
    source(note)
  ]
end

def parse(file = './notes.enex')
  Nokogiri::XML File.read(file)..xpath('//note').map do |note|
    title, content, tags, time, source = parts(note)
    { title: title, note: note, content: <<-END
#{title}
====================
Created At: #{time}
URL: #{source}
Tags: #{tags.join ','}
#{content}
END
    }
  end
end

def output_note(note)
  title = note[:title].gsub '/', '__'
  title = title[0..50] if title.length > 100
  file = "./notes/#{title}.txt"
  File.open(file, 'w') do |f|
    f.write note[:content]
  end
end

def delete(note_title)
  puts "Deleting '#{note_title}'"
  # command = "/usr/local/bin/geeknote remove --note \"#{note_title}\""
  # IO.popen(command, 'r+', err: [:child, :out]) do |io|
  #   io.puts 'Yes'
  #   puts io.readlines
  # end
  puts "Finished deleting #{note_title}"
end

def run
  notes = parse
  puts "There are #{notes.count} notes to migrate."

  notes.each do |note|
    output_note note
    # delete note[:title]
  end
  puts 'All done migrating notes.'
end

run if __FILE__ == $PROGRAM_NAME
